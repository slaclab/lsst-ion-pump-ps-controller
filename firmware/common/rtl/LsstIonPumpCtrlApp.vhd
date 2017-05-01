-------------------------------------------------------------------------------
-- File       : LsstIonPumpCtrlApp.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-05-01
-- Last update: 2017-05-01
-------------------------------------------------------------------------------
-- Description: Top Level Application
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

entity LsstIonPumpCtrlApp is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_CLK_FREQ_C   : real             := 125.0E+6;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := x"0000_0000";
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Ion Pump Control Board ADC SPI Interfaces
      iMonDin         : in  slv(5 downto 0);  -- Serial in from Current Mon ADC
      vMonDin         : in  slv(5 downto 0);  -- Serial in from Voltage Mon ADC
      pMonDin         : in  slv(5 downto 0);  -- Serial in from Power Mon ADC
      adcSClk         : out slv(5 downto 0);  -- Clock for Monitor ADCs
      -- Ion Pump Control Board ADC SPI Interfaces
      dacDout         : out slv(5 downto 0);  -- Serial out for Setpoint DACs
      dacSclk         : out slv(5 downto 0);  -- Clock for the Setpoint DACs
      iProgCsL        : out sl;         -- Chip Enable for Current DAC
      vProgCsL        : out sl;         -- Chip Enable for Voltage DAC
      pProgCsL        : out sl;         -- Chip Enable for Power DAC
      -- Ion Pump Control Board Mode bits
      iMode           : in  slv(5 downto 0);  -- HVPS in Current Limit Mode
      vMode           : in  slv(5 downto 0);  -- HVPS in Voltage Limit Mode
      pMode           : in  slv(5 downto 0);  -- HVPS in Power Limit Mode
      -- Ion Pump Enable
      enable          : out slv(5 downto 0));  -- Enable HVPS
end LsstIonPumpCtrlApp;

architecture app of LsstIonPumpCtrlApp is

begin

   -- placeholder for future code
   dacDout  <= (others => '1');
   dacSclk  <= (others => '1');
   iProgCsL <= '1';
   vProgCsL <= '1';
   pProgCsL <= '1';
   enable   <= (others => '1');
   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

end app;
