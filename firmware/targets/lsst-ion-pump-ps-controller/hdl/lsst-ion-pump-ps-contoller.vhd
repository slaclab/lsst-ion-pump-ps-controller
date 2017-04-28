-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      lsst-ion-pump-ps-contoller.vhd - 
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 4/20/2017 2:04:46 PM
--      Last change: JO 4/27/2017 1:04:52 PM
--
-------------------------------------------------------------------------------
-- File       : lsst-ion-pump-ps-contoller.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-04
-- Last update: 2017-04-27
-------------------------------------------------------------------------------
-- Description: Firmware Target's Top Level
-- 
-- Note: Common-to-Application interface defined in HPS ESD: LCLSII-2.7-ES-0536
-- 
-------------------------------------------------------------------------------
-- This file is part of 'firmware-template'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'firmware-template', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.GigEthPkg.all;


entity IonPumpController is
  generic (
    TPD_G        : time := 1 ns;
    BUILD_INFO_G : BuildInfoType
    );
  port (
    ResetN : in sl;

-- MGT Ethernet/UDP
    mgtClkP : in  sl;
    mgtClkM : in  sl;
    txP     : out sl;
    txM     : out sl;
    rxP     : in  sl;
    rxM     : in  sl;

-- Boot Prom IO
    bootSck  : out sl;
    bootDout : out slv(3 downto 0);
    bootCsN  : out sl;

-- Scratch Pad Prom
    promScl : in sl;
    promSda : in sl;

-- Ion Pump Control Board ADC SPI Interfaces
    iMonDin : in  slv(5 downto 0);      -- Serial in from Current Mon ADC
    vMonDin : in  slv(5 downto 0);      -- Serial in from Voltage Mon ADC
    pMonDin : in  slv(5 downto 0);      -- Serial in from Power Mon ADC
    adcSClk : out slv(5 downto 0);      -- Clock for Monitor ADCs

-- Ion Pump Control Board ADC SPI Interfaces
    dacDout  : out slv(5 downto 0);     -- Serial out for Setpoint DACs
    dacSclk  : out slv(5 downto 0);     -- Clock for the Setpoint DACs
    iProgCsN : out sl;                  -- Chip Enable for Current DAC
    vProgCsN : out sl;                  -- Chip Enable for Voltage DAC
    pProgCsN : out sl;                  -- Chip Enable for Power DAC

-- Ion Pump Control Board Mode bits
    iMode : in slv(5 downto 0);         -- HVPS in Current Limit Mode
    vMode : in slv(5 downto 0);         -- HVPS in Voltage Limit Mode
    pMode : in slv(5 downto 0);         -- HVPS in Power Limit Mode

-- Ion Pump Enable
    enable : out slv(5 downto 0)        -- Enable HVPS
    );
end IonPumpController;

architecture top_level of IonPumpController is

  signal sysClk   : sl;
  signal sysReset : sl;

  signal txMasters : AxiStreamMasterArray(0 downto 0);
  signal txSlaves  : AxiStreamSlaveArray(0 downto 0);
  signal rxMasters : AxiStreamMasterArray(0 downto 0);
  signal rxSlaves  : AxiStreamSlaveArray(0 downto 0);

  constant NUM_AXI_MASTERS_C   : natural := 4;
  constant ETHERNET_INDEX_C    : natural := 0;  -- Ethernet UDP Interface
  constant VERSION_INDEX_C     : natural := 1;  -- Version Interface
  constant BOOT_PROM_INDEX_C   : natural := 2;  -- Boot PROM
  constant ION_CONTROL_INDEX_C : natural := 3;  -- Ion Pump Control Registers and SPI

  constant ETHERNET_BASE_ADDR_C    : slv(31 downto 0) := x"0000_0000" + AXIL_BASE_ADDR_G;
  constant VERSION_BASE_ADDR_C     : slv(31 downto 0) := x"0001_0000" + AXIL_BASE_ADDR_G;
  constant BOOT_PROM_BASE_ADDR_C   : slv(31 downto 0) := x"0002_0000" + AXIL_BASE_ADDR_G;
  constant ION_CONTROL_BASE_ADDR_C : slv(31 downto 0) := x"0003_0000" + AXIL_BASE_ADDR_G;

  constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) :=
    (
      ETHERNET_INDEX_C    => (
        baseAddr          => ETHERNET_BASE_ADDR_C,
        addrBits          => 16,
        connectivity      => x"FFFF"
        ),
      VERSION_INDEX_C     => (
        baseAddr          => VERSION_BASE_ADDR_C,
        addrBits          => 16,
        connectivity      => x"FFFF"
        ),
      BOOT_PROM_INDEX_C   => (
        baseAddr          => BOOT_PROM_BASE_ADDR_C,
        addrBits          => 16,
        connectivity      => x"FFFF"
        ),
      ION_CONTROL_INDEX_C => (
        baseAddr          => ION_CONTROL_BASE_ADDR_C,
        addrBits          => 16,
        connectivity      => x"FFFF"
        )
      );

  signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

begin

  bootData(3 downto 1) <= (others => '0');

  u_Xbar : entity work.AxiLiteCrossbar
    generic map (
      TPD_G              => TPD_G,
      DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
      NUM_SLAVE_SLOTS_G  => 2,
      NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
      MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C
      )
    port map (
      axiClk           => SysClk,
      axiClkRst        => SysRst,
      sAxiWriteMasters => sAxilWriteMasters,
      sAxiWriteSlaves  => sAxilWriteSlaves,
      sAxiReadMasters  => sAxilReadMasters,
      sAxiReadSlaves   => sAxilReadSlaves,
      mAxiWriteMasters => axilWriteMasters,
      mAxiWriteSlaves  => axilWriteSlaves,
      mAxiReadMasters  => axilReadMasters,
      mAxiReadSlaves   => axilReadSlaves
      );

  u_Ethernet : entity work.GigEthGtp7Wrapper
    generic map (
      TPD_G              => TPD_G,
      NUM_LANE_G         => 1,
-- Clocking Configurations
      USE_GTREFCLK_G     => false,  --       FALSE: gtClkP/N,        TRUE: gtRefClk
      CLKIN_PERIOD_G     => 8.0,
      DIVCLK_DIVIDE_G    => 1,
      CLKFBOUT_MULT_F_G  => 8.0,
      CLKOUT0_DIVIDE_F_G => 8.0,
-- AXI-Lite Configurations
      EN_AXI_REG_G       => false,
      AXI_ERROR_RESP_G   => AXI_RESP_SLVERR_C,
-- AXI Streaming Configurations
      AXIS_CONFIG_G      => (others => AXI_STREAM_CONFIG_INIT_C)
      )
    port map (
-- Local Configurations
      localMac            => (others => MAC_ADDR_INIT_C),
-- Streaming DMA Interface
      dmaClk(0)           => sysClk,
      dmaRst(0)           => sysReset,
      dmaIbMasters        => rxMasters,
      dmaIbSlaves         => rxSlaves,
      dmaObMasters        => txMasters,
      dmaObSlaves         => txSlaves,
-- Slave AXI-Lite Interface
      axiLiteClk(0)       => sysClk,
      axiLiteRst(0)       => sysReset,
      axiLiteReadMasters  => axilReadMasters(ETHERNET_C downto ETHERNET_C),
      axiLiteReadSlaves   => axilReadSlaves(ETHERNET_C downto ETHERNET_C),
      axiLiteWriteMasters => axilWriteMasters(ETHERNET_C downto ETHERNET_C),
      axiLiteWriteSlaves  => axilWriteSlaves(ETHERNET_C downto ETHERNET_C),
-- Misc. Signals
      extRst              => sysReset,
      phyClk              => sysClk,
      phyRst              => open,
      phyReady            => open,
      sigDet              => "0",
-- MGT Clock Port (156.25 MHz or 312.5 MHz)
      gtRefClk            => '0',
      gtClkP              => mgtClkP,
      gtClkN              => mgtClkM,
-- MGT Ports
      gtTxP(0)            => txP,
      gtTxN(0)            => txM,
      gtRxP(0)            => rxP,
      gtRxN(0)            => rxM
      );

  u_Version : entity work.AxiVersion
    generic map (
      TPD_G              => TPD_G,
      BUILD_INFO_G       => BUILD_INFO_G,
--      SIM_DNA_VALUE_G  => X"000000000000000000000000",
      AXI_ERROR_RESP_G   => AXI_RESP_DECERR_C,
      DEVICE_ID_G        => (others => '0'),
      CLK_PERIOD_G       => 8.0E-9,     -- units of seconds
      XIL_DEVICE_G       => "7SERIES",  -- Either "7SERIES" or "ULTRASCALE"
      EN_DEVICE_DNA_G    => true,
      EN_DS2411_G        => true,
      EN_ICAP_G          => true,
      USE_SLOWCLK_G      => true,
      BUFR_CLK_DIV_G     => 8,
      AUTO_RELOAD_EN_G   => false,
      AUTO_RELOAD_TIME_G => 10.0,       -- units of seconds
      AUTO_RELOAD_ADDR_G => (others => '0')
      )
    port map (
-- AXI-Lite Interface
      axiClk             => sysClk(0),
      axiRst             => sysReset(0),
      axiLiteReadMaster  => axilReadMasters(VERSION_INDEX_C),
      axiLiteReadSlave   => axilReadSlaves(VERSION_INDEX_C),
      axiLiteWriteMaster => axilWriteMasters(VERSION_INDEX_C),
      axiLiteWriteSlave  => axilWriteSlaves(VERSION_INDEX_C),
-- Optional: Master Reset
      masterReset        => open,
-- Optional: FPGA Reloading Interface
      fpgaEnReload       => '1',
      fpgaReload         => open,
      fpgaReloadAddr     => open,
      upTimeCnt          => open,
-- Optional: Serial Number outputs
      slowClk            => sysClk,
      dnaValueOut        => open,
      fdValueOut         => open,
-- Optional: user values
      userValues         => (others => X"00000000"),
-- Optional: DS2411 interface
      fdSerSdio          => 'Z')
    );

  u_Micron : entity work.AxiMicronN25QCore
    generic map (
      TPD_G            => 1 ns,
      MEM_ADDR_MASK_G  => x"00000000",
      AXI_CLK_FREQ_G   => 200.0E+6,     -- units of Hz
      SPI_CLK_FREQ_G   => 25.0E+6,      -- units of Hz
      PIPE_STAGES_G    => 0,
--      AXI_CONFIG_G     => ssiAxiStreamConfig(4),
      AXI_ERROR_RESP_G => AXI_RESP_SLVERR_C)
    port map (
      -- FLASH Memory Ports
      csL            => bootCsN,
      sck            => bootSck,
      mosi           => bootData(0),
      miso           => '0',
      -- AXI-Lite Register Interface
      axiReadMaster  => axilReadMasters(BOOT_PROM_INDEX_C),
      axiReadSlave   => axilReadSlaves(BOOT_PROM_INDEX_C),
      axiWriteMaster => axilWriteMasters(BOOT_PROM_INDEX_C),
      axiWriteSlave  => axilWriteSlaves(BOOT_PROM_INDEX_C),
      -- AXI Streaming Interface (Optional)
      mAxisMaster    => open,
      mAxisSlave     => AXI_STREAM_SLAVE_FORCE_C,
      sAxisMaster    => AXI_STREAM_MASTER_INIT_C,
      sAxisSlave     => open,
      -- Clocks and Resets
      axiClk         => sysClk,
      axiRst         => sysReset
      );

  u_IonPumpApp : entity work.IonPumpApp
    generic map (
      TPD_G            => TPD_G,
      AXIL_BASE_ADDR_G => AXI_CONFIG_C(ION_CONTROL_INDEX_C).baseAddr,
      AXI_ERROR_RESP_G => AXI_ERROR_RESP_G
      )
    port map (

-- Slave AXI-Lite Interface
      axiLiteClk         => sysClk,
      axiLiteRst         => sysReset,
      axiLiteReadMaster  => axilReadMasters(ION_CONTROL_INDEX_C),
      axiLiteReadSlave   => axilReadSlaves(ION_CONTROL_INDEX_C),
      axiLiteWriteMaster => axilWriteMasters(ION_CONTROL_INDEX_C),
      axiLiteWriteSlave  => axilWriteSlaves(ION_CONTROL_INDEX_C),

-- Controller IO
-- Ion Pump Control Board ADC SPI Interfaces
      I_Mon_Din => iMonDin,             -- Serial in from Current Mon ADC
      V_Mon_Din => vMonDin,             -- Serial in from Voltage Mon ADC
      P_Mon_Din => pMonDin,             -- Serial in from Power Mon ADC
      ADC_SClk  => adcSclk,             -- Clock for Monitor ADCs

-- Ion Pump Control Board ADC SPI Interfaces
      dacDout  => dacDout,              -- Serial out for Setpoint DACs
      dacSclk  => dacSclk,              -- Clock for the Setpoint DACs
      iProgCsN => iProgCsN,             -- Chip Enable for Current DAC
      vProgCsN => vProgCsN,             -- Chip Enable for Voltage DAC
      pProgCsN => pProgCsN,             -- Chip Enable for Power DAC

-- Ion Pump Control Board Mode bits
      iMode => iMode,                   -- HVPS in Current Limit Mode
      vMode => vMode,                   -- HVPS in Voltage Limit Mode
      pMode => pMode,                   -- HVPS in Power Limit Mode

-- Ion Pump Enable
      Enable => Enable                  -- Enable HVPS
      );


end top_level;
