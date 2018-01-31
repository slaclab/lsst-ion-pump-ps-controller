-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      LsstIonPumpCtrlApp.vhd -
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 4/20/2017 2:04:46 PM
--      Last change: JO 1/30/2018 3:45:53 PM
--
-------------------------------------------------------------------------------
-- File       : lsst-ion-pump-ps-contoller.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-04
-- Last update: 2017-08-02
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
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;



entity LsstIonPumpCtrlApp is
  generic (
    TPD_G            : time            := 1ns;
    AXI_BASE_ADDR_G    : slv(31 downto 0)        := x"00000000";
    AXI_CLK_FREQ_C   : real            := 156.0E+6;
    AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C

    );
  port (

-- Slave AXI-Lite Interface
    axilClk         : in  sl;
    axilRst         : in  sl;
    axilReadMaster  : in  AxiLiteReadMasterType;
    axilReadSlave   : out AxiLiteReadSlaveType;
    axilWriteMaster : in  AxiLiteWriteMasterType;
    axilWriteSlave  : out AxiLiteWriteSlaveType;

-- Controller IO
-- Ion Pump Control Board ADC SPI Interfaces
    iMonDin : in  slv(5 downto 0);      -- Serial in from Current Mon ADC
    vMonDin : in  slv(5 downto 0);      -- Serial in from Voltage Mon ADC
    pMonDin : in  slv(5 downto 0);      -- Serial in from Power Mon ADC
    adcSClk : out slv(5 downto 0);      -- Clock for Monitor ADCs

-- Ion Pump Control Board ADC SPI Interfaces
    dacDout  : out slv(5 downto 0);     -- Serial out for Setpoint DACs
    dacSclk  : out slv(5 downto 0);     -- Clock for the Setpoint DACs
    iProgCsL : out slv(5 downto 0);     -- Chip Enable for Current DAC
    vProgCsL : out slv(5 downto 0);     -- Chip Enable for Voltage DAC
    pProgCsL : out slv(5 downto 0);     -- Chip Enable for Power DAC

-- Ion Pump Control Board Mode bits
    iMode : in slv(5 downto 0);         -- HVPS in Current Limit Mode
    vMode : in slv(5 downto 0);         -- HVPS in Voltage Limit Mode
    pMode : in slv(5 downto 0);         -- HVPS in Power Limit Mode

-- Ion Pump Enable
    Enable : out slv(5 downto 0)        -- Enable HVPS
    );
end entity LsstIonPumpCtrlApp;

architecture Behavioral of LsstIonPumpCtrlApp is

 
  -------------------------------------------------------------------------------------------------
  -- AXI Lite Config and Signals
  -------------------------------------------------------------------------------------------------

  constant BOARD_INDEX_C : natural := 0;

  constant NUM_AXI_MASTERS_C : natural := 6;

  constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
    BOARD_INDEX_C   => (
      baseAddr      => AXI_BASE_ADDR_G + x"0000_0000",
      addrBits      => 12,
      connectivity  => X"0001"),
    BOARD_INDEX_C+1 => (
      baseAddr      => AXI_BASE_ADDR_G + x"0000_1000",
      addrBits      => 12,
      connectivity  => X"0001"),
    BOARD_INDEX_C+2 => (
      baseAddr      => AXI_BASE_ADDR_G + x"0000_2000",
      addrBits      => 12,
      connectivity  => X"0001"),
    BOARD_INDEX_C+3 => (
      baseAddr      => AXI_BASE_ADDR_G + x"0000_3000",
      addrBits      => 12,
      connectivity  => X"0001"),
    BOARD_INDEX_C+4 => (
      baseAddr      => AXI_BASE_ADDR_G + x"0000_4000",
      addrBits      => 12,
      connectivity  => X"0001"),
    BOARD_INDEX_C+5 => (
      baseAddr      => AXI_BASE_ADDR_G + x"0000_5000",
      addrBits      => 12,
      connectivity  => X"0001")
    );

  signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

begin


  ---------------------------
  -- AXI-Lite Crossbar Module
  ---------------------------        
  U_Xbar : entity work.AxiLiteCrossbar
    generic map (
      TPD_G              => TPD_G,
      DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
      NUM_SLAVE_SLOTS_G  => 1,
      NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
      MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
    port map (
      axiClk              => axilClk,
      axiClkRst           => axilRst,
      sAxiWriteMasters(0) => axilWriteMaster,
      sAxiWriteSlaves(0)  => axilWriteSlave,
      sAxiReadMasters(0)  => axilReadMaster,
      sAxiReadSlaves(0)   => axilReadSlave,
      mAxiWriteMasters    => LocAxilWriteMasters,
      mAxiWriteSlaves     => LocAxilWriteSlaves,
      mAxiReadMasters     => LocAxilReadMasters,
      mAxiReadSlaves      => LocAxilReadSlaves);

  genFrontEnd : for I in 0 to 5 generate
    uFrontEnd : entity work.FrontEndBoard
      generic map (
        TPD_G            => 1 ns,
        AXI_BASE_ADDR_G  => AXI_CROSSBAR_MASTERS_CONFIG_C(i).baseAddr,
        AXI_ERROR_RESP_G => AXI_RESP_DECERR_C,
        CLK_PERIOD_G     => 6.4E-9      -- 156Mhz
        )
      port map (
        axilClk => axilClk,
        axilRst => axilRst,

        axiLReadMaster  => LocAxilReadMasters(BOARD_INDEX_C+I),
        axiLReadSlave   => LocAxilReadSlaves(BOARD_INDEX_C+I),
        axiLWriteMaster => LocAxilWriteMasters(BOARD_INDEX_C+I),
        axiLWriteSlave  => LocAxilWriteSlaves(BOARD_INDEX_C+I),

-- Controller IO
-- Ion Pump Control Board ADC SPI Interfaces
        iMonDin => iMonDin(I),          -- Serial in from Current Mon ADC
        vMonDin => vMonDin(I),          -- Serial in from Voltage Mon ADC
        pMonDin => pMonDin(I),          -- Serial in from Power Mon ADC
        adcSClk => adcSclk(I),          -- Clock for Monitor ADCs

-- Ion Pump Control Board ADC SPI Interfaces
        dacDout  => dacDout(I),         -- Serial out for Setpoint DACs
        dacSclk  => dacSclk(I),         -- Clock for the Setpoint DACs
        iProgCsL => iProgCsL(I),        -- Chip Enable for Current DAC
        vProgCsL => vProgCsL(I),        -- Chip Enable for Voltage DAC
        pProgCsL => pProgCsL(I),        -- Chip Enable for Power DAC

-- Ion Pump Control Board Mode bits
        iMode => iMode(I),              -- HVPS in Current Limit Mode
        vMode => vMode(I),              -- HVPS in Voltage Limit Mode
        pMode => pMode(I),              -- HVPS in Power Limit Mode

-- Ion Pump Enable
        enable => enable(I)             -- Enable HVPS
        );
  end generate;
end Behavioral;


