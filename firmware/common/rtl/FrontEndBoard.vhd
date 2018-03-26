-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      FrontEndBoard.vhd -
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 4/20/2017 2:04:46 PM
--      Last change: JO 2/1/2018 4:37:43 PM
--
-------------------------------------------------------------------------------
-- File       : FrontEndBoardvhd
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

entity FrontEndBoard is
  generic (
    TPD_G            : time            := 1 ns;
    AXI_BASE_ADDR_G    : slv(31 downto 0)        := x"00000000";
    AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C;
    CLK_PERIOD_G     : real            := 6.4E-9  -- 156Mhz
    );
  port (

-- Slave AXI-Lite Interface
    axilClk        : in  sl;
    axilRst        : in  sl;
    axilReadMaster  : in  AxiLiteReadMasterType;
    axilReadSlave   : out AxiLiteReadSlaveType;
    axilWriteMaster : in  AxiLiteWriteMasterType;
    axilWriteSlave  : out AxiLiteWriteSlaveType;

-- Controller IO
-- Ion Pump Control Board ADC SPI Interfaces
    iMonDin : in  sl;                   -- Serial in from Current Mon ADC
    vMonDin : in  sl;                   -- Serial in from Voltage Mon ADC
    pMonDin : in  sl;                   -- Serial in from Power Mon ADC
    adcSClk : out sl;                   -- Clock for Monitor ADCs

-- Ion Pump Control Board DAC SPI Interfaces
    dacDout  : out sl;                  -- Serial out for Setpoint DACs
    dacSclk  : out sl;                  -- Clock for the Setpoint DACs
    iProgCsL : out sl;                  -- Chip Enable for Current DAC
    vProgCsL : out sl;                  -- Chip Enable for Voltage DAC
    pProgCsL : out sl;                  -- Chip Enable for Power DAC

-- Ion Pump Control Board Mode bits
    iMode : in sl;                      -- HVPS in Current Limit Mode
    vMode : in sl;                      -- HVPS in Voltage Limit Mode
    pMode : in sl;                      -- HVPS in Power Limit Mode

-- Ion Pump Enable
    enable : out sl                     -- Enable HVPS
    );
end entity FrontEndBoard;

architecture Behavioral of FrontEndBoard is

  signal idacSclk    : sl;
  signal idacDout    : sl;
  signal iCsb        : slv(2 downto 0);
  signal adcIn       : slv(2 downto 0);

  -------------------------------------------------------------------------------------------------
  -- AXI Lite Config and Signals
  -------------------------------------------------------------------------------------------------

  constant NUM_AXI_MASTERS_C : natural := 3;
  
  constant REG_INDEX_C       : natural := 0;
  constant DAC_INDEX_C          : natural := 1;
  constant ADC_INDEX_C          : natural := 2;

  constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
    REG_INDEX_C    => (
      baseAddr     => AXI_BASE_ADDR_G + X"0000_0000",
      addrBits     => 8,
      connectivity => X"0001"),
    DAC_INDEX_C  => (
      baseAddr     =>AXI_BASE_ADDR_G +  x"0000_0100",
      addrBits     => 8,
      connectivity => X"0001"),
    ADC_INDEX_C  => (
      baseAddr     => AXI_BASE_ADDR_G + x"0000_0400",
      addrBits     => 8,
      connectivity => X"0001")
    );

  signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal iadcSclk            : slv(2 downto 0);

begin

  iProgCsL <= iCsb(0);
  vProgCsL <= iCsb(1);
  pProgCsL <= iCsb(2);

  adcSclk <= iadcSclk(0);
  DacDout <= idacDout;
  DacSclk <= idacSclk;

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


  adcIn(0) <= iMonDin;
  adcIn(1) <= vMonDin;
  adcIn(2) <= pMonDin;

--  uFrontEndReg : entity work.FrontEndReg
--    generic map (
--      TPD_G            => 1 ns,
--      AXI_ERROR_RESP_G => AXI_RESP_DECERR_C
--      )
--    port map (
--      axilClk => axilClk,
--      axilRst => axilRst,


--      axilReadMaster  => locAxilReadMasters(REG_INDEX_C),
--      axilReadSlave   => locAxilReadSlaves(REG_INDEX_C),
--      axilWriteMaster => locAxilWriteMasters(REG_INDEX_C),
--      axilWriteSlave  => locAxilWriteSlaves(REG_INDEX_C),

--      iMode  => iMode,
--      vMode  => vMode,
--      pMode  => pMode,
--      Enable => enable
--      );


    uDacSpi : entity work.AxiSpiMaster
      generic map (
        TPD_G             => 1 ns,
        AXI_ERROR_RESP_G  => AXI_RESP_DECERR_C,
        ADDRESS_SIZE_G    => 0,
        DATA_SIZE_G       => 16,
        MODE_G            => "WO",  -- Or "WO" (write only),  "RO" (read only)
        CPHA_G            => '0',
        CPOL_G            => '0',
        CLK_PERIOD_G      => 6.4E-9,    -- 156Mhz
        SPI_NUM_CHIPS_G   => 3, 
        SPI_SCLK_PERIOD_G => 1.0E-6
        )
      port map (
        axiClk => axilClk,
        axiRst => axilRst,

        axiReadMaster  => locAxilReadMasters(DAC_INDEX_C),
        axiReadSlave   => locAxilReadSlaves(DAC_INDEX_C),
        axiWriteMaster => locAxilWriteMasters(DAC_INDEX_C),
        axiWriteSlave  => locAxilWriteSlaves(DAC_INDEX_C),

        coreSclk  => idacSclk,
        coreSDin  => '0',
        coreSDout => idacDout,
        coreMCsb   => iCsb
        );

--    uADC : entity work.AxiMax11202Master
--      generic map (
--        TPD_G                => 1 ns,
--        AXI_ERROR_RESP_G     => AXI_RESP_DECERR_C,
--        CLK_PERIOD_G         => 6.4E-9,
--        SERIAL_SCLK_PERIOD_G => 1.0E-6
--        )
--      port map (
--        axiClk => axilClk,
--        axiRst => axilRst,

--        axiReadMaster  => locAxilReadMasters(ADC_INDEX_C),
--        axiReadSlave   => locAxilReadSlaves(ADC_INDEX_C),
--        axiWriteMaster => locAxilWriteMasters(ADC_INDEX_C),
--        axiWriteSlave  => locAxilWriteSlaves(ADC_INDEX_C),

--        coreSclk => ADCSClk,
--        coreSDin => adcIn
--
--        );



end Behavioral;


