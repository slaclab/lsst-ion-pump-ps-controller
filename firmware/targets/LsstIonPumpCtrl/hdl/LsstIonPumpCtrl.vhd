-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      LsstIonPumpCtrl.vhd - 
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 7/19/2017 1:33:09 PM
--      Last change: JO 8/2/2017 9:40:28 AM
--
-------------------------------------------------------------------------------
-- File       : LsstIonPumpCtrl.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-20
-- Last update: 2018-02-14
-------------------------------------------------------------------------------
-- Description: Firmware Target's Top Level
-------------------------------------------------------------------------------
-- This file is part of 'LSST Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LSST Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity LsstIonPumpCtrl is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      -- Ion Pump Control Board ADC SPI Interfaces
      iMonDin  : in    slv(5 downto 0);  -- Serial in from Current Mon ADC
      vMonDin  : in    slv(5 downto 0);  -- Serial in from Voltage Mon ADC
      pMonDin  : in    slv(5 downto 0);  -- Serial in from Power Mon ADC
      adcSClk  : out   slv(5 downto 0);  -- Clock for Monitor ADCs
      -- Ion Pump Control Board ADC SPI Interfaces
      dacDout  : out   slv(5 downto 0);  -- Serial out for Setpoint DACs
      dacSclk  : out   slv(5 downto 0);  -- Clock for the Setpoint DACs
      iProgCsL : out   slv(5 downto 0);  -- Chip Enable for Current DAC
      vProgCsL : out   slv(5 downto 0);  -- Chip Enable for Voltage DAC
      pProgCsL : out   slv(5 downto 0);  -- Chip Enable for Power DAC
      -- Ion Pump Control Board Mode bits
      iMode    : in    slv(5 downto 0);  -- HVPS in Current Limit Mode
      vMode    : in    slv(5 downto 0);  -- HVPS in Voltage Limit Mode
      pMode    : in    slv(5 downto 0);  -- HVPS in Power Limit Mode
      -- Ion Pump Enable
      enable   : out   slv(5 downto 0);  -- Enable HVPS
      -- Boot Memory Ports
      bootCsL  : out   sl;
      bootMosi : out   sl;
      bootMiso : in    sl;
      -- Scratch Pad Prom
      promScl  : inout sl;
      promSda  : inout sl;
      -- 1GbE Ports
      ethClkP  : in    sl;
      ethClkN  : in    sl;
      ethRxP   : in    sl;
      ethRxN   : in    sl;
      ethTxP   : out   sl;
      ethTxN   : out   sl;
      -- Misc.
      extRstL  : in    sl;
      -- XADC Ports
      vPIn     : in    sl;
      vNIn     : in    sl);
end LsstIonPumpCtrl;

architecture top_level of LsstIonPumpCtrl is

   constant SYS_CLK_FREQ_C      : real                                         := 156.0E+6;
   constant AXI_CONFIG_C        : AxiLiteCrossbarMasterConfigArray(6 downto 0) := genAxiLiteConfig(7, x"0000_0000", 22, 18);
   constant PROM_I2C_INDEX_C    : natural                                      := 0;
   constant ION_CONTROL_INDEX_C : natural                                      := 1;

   signal axilClk          : sl;
   signal axilRst          : sl;
   signal axilWriteMasters : AxiLiteWriteMasterArray(6 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(6 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(6 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(6 downto 0);

begin

   ---------------------
   -- Common Core Module
   ---------------------
   U_Core : entity work.LsstPwrCtrlCore
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G)
      port map (
         -- Register Interface
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMasters  => axilReadMasters,
         axilReadSlaves   => axilReadSlaves,
         axilWriteMasters => axilWriteMasters,
         axilWriteSlaves  => axilWriteSlaves,
         -- Misc.
         extRstL          => extRstL,
         -- XADC Ports
         vPIn             => vPIn,
         vNIn             => vNIn,
         -- Boot Memory Ports
         bootCsL          => bootCsL,
         bootMosi         => bootMosi,
         bootMiso         => bootMiso,
         -- 1GbE Interface
         ethClkP          => ethClkP,
         ethClkN          => ethClkN,
         ethRxP           => ethRxP,
         ethRxN           => ethRxN,
         ethTxP           => ethTxP,
         ethTxN           => ethTxN);

   ----------------------------------
   -- Terminate Unused AXI-Lite buses
   ----------------------------------
   GEN_VEC :
   for i in 6 downto 2 generate

      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G => TPD_G)
         port map (
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMasters(i),
            axiReadSlave   => axilReadSlaves(i),
            axiWriteMaster => axilWriteMasters(i),
            axiWriteSlave  => axilWriteSlaves(i));

   end generate GEN_VEC;

   ----------------------------------------
   -- AXI-Lite: Configuration Memory Module
   ----------------------------------------
   U_I2cProm : entity work.AxiI2cEeprom
      generic map (
         TPD_G          => TPD_G,
         ADDR_WIDTH_G   => 13,          -- Need to verify this value!!!
         I2C_ADDR_G     => "1010000",   -- Need to verify this value!!!
         AXI_CLK_FREQ_G => SYS_CLK_FREQ_C)
      port map (
         -- I2C Ports
         scl             => promScl,
         sda             => promSda,
         -- AXI-Lite Register Interface
         axilReadMaster  => axilReadMasters(PROM_I2C_INDEX_C),
         axilReadSlave   => axilReadSlaves(PROM_I2C_INDEX_C),
         axilWriteMaster => axilWriteMasters(PROM_I2C_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PROM_I2C_INDEX_C),
         -- Clocks and Resets
         axilClk         => axilClk,
         axilRst         => axilRst);

   ---------------------------------
   -- AXI-Lite: Ion Pump Application
   ---------------------------------
   U_App : entity work.LsstIonPumpCtrlApp
      generic map (
         TPD_G           => TPD_G,
         AXI_CLK_FREQ_C  => SYS_CLK_FREQ_C,
         AXI_BASE_ADDR_G => AXI_CONFIG_C(ION_CONTROL_INDEX_C).baseAddr)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(ION_CONTROL_INDEX_C),
         axilReadSlave   => axilReadSlaves(ION_CONTROL_INDEX_C),
         axilWriteMaster => axilWriteMasters(ION_CONTROL_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(ION_CONTROL_INDEX_C),
         -- Controller IO
         -- Ion Pump Control Board ADC SPI Interfaces
         iMonDin         => iMonDin,    -- Serial in from Current Mon ADC
         vMonDin         => vMonDin,    -- Serial in from Voltage Mon ADC
         pMonDin         => pMonDin,    -- Serial in from Power Mon ADC
         adcSClk         => adcSclk,    -- Clock for Monitor ADCs
         -- Ion Pump Control Board ADC SPI Interfaces
         dacDout         => dacDout,    -- Serial out for Setpoint DACs
         dacSclk         => dacSclk,    -- Clock for the Setpoint DACs
         iProgCsL        => iProgCsL,   -- Chip Enable for Current DAC
         vProgCsL        => vProgCsL,   -- Chip Enable for Voltage DAC
         pProgCsL        => pProgCsL,   -- Chip Enable for Power DAC
         -- Ion Pump Control Board Mode bits
         iMode           => iMode,      -- HVPS in Current Limit Mode
         vMode           => vMode,      -- HVPS in Voltage Limit Mode
         pMode           => pMode,      -- HVPS in Power Limit Mode
         -- Ion Pump Enable
         enable          => enable);    -- Enable HVPS

end top_level;
