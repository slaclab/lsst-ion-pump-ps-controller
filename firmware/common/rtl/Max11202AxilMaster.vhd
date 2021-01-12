-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      Max11202axilMaster.vhd -
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 7/18/2017 9:35:50 AM
--      Last change: JO 4/19/2018 11:16:48 AM
--
-------------------------------------------------------------------------------
-- Title      : Axi lite interface for a Max11202 ADC
-------------------------------------------------------------------------------
-- File       : AxiMax11202Master.vhd
-- From           : AxiSpiMaster by
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-01-12
-- Last update: 2018-04-19
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- There are 5 modes of operation.
-- 0 -- Read and leave Dout at LSB, 24 Clock ticks.
--      A new conversion starts after the 24th Clock tick.
--      This mode does not seem very usefull
-- 1 -- Read and leave Dout High, 25 Clock ticks.
--      A new conversion start after 25th Clock tick.
-- 2 -- Read, leave Dout High, 26 Clock ticks
--      A calibration and new convert start after 26th clock.
-- 3 -- Read, leave Dout High and go to sleep, 23-1/2 Clock ticks.
--      Conversion starts when Clock goes low.
-- 4 -- Read, leave Dout High, Sleep, 25-1/2 Clock ticks.
--      Calibration and conversion start when the Clock goes low.
--
--
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC Firmware Standard Library', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity Max11202AxilMaster is
  generic (
    TPD_G                : time := 1 ns;
    CLK_PERIOD_G         : real := 8.0E-9;
    SERIAL_SCLK_PERIOD_G : real := 1.0E-6
    );
  port (
    axiClk : in sl;
    axiRst : in sl;

    axiReadMaster  : in  AxiLiteReadMasterType;
    axiReadSlave   : out AxiLiteReadSlaveType;
    axiWriteMaster : in  AxiLiteWriteMasterType;
    axiWriteSlave  : out AxiLiteWriteSlaveType;

    -- Start Conversion
    StartConv : in sl;

    coreSclk : out sl;
    coreSDin : in  slv(2 downto 0)
    );
end entity Max11202axilMaster;

architecture rtl of Max11202axilMaster is

  type data32 is array (2 downto 0) of slv(31 downto 0);

  signal rdData : data32;

  type StateType is (WAIT_axil_TXN_S, WAIT_CYCLE_S, WAIT_SERIAL_TXN_DONE_S);

  -- Registers
  type RegType is record
    state          : StateType;
    axiReadSlave  : AxiLiteReadSlaveType;
    axiWriteSlave : AxiLiteWriteSlaveType;
  end record RegType;

  constant REG_INIT_C : RegType := (
    state          => WAIT_axil_TXN_S,
    axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C
    );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

begin

  comb : process (axiReadMaster, axiRst, axiWriteMaster, r, rdData) is
    variable v          : RegType;
    variable axilStatus : AxiLiteStatusType;
    variable RAddr      : integer;
  begin
    v     := r;
    RAddr := to_integer(unsigned(axiReadMaster.araddr(3 downto 2)));

    -- Determine the transaction type
    axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axilStatus);

    -- Check for a read request
    if (axilStatus.readEnable = '1') then
      v.axiReadSlave.rdata := RdData(RAddr);
      -- Send AXI-Lite Response
      axiSlaveReadResponse(v.axiReadSlave, AXI_RESP_OK_C);
    end if;

    if (axiRst = '1') then
      v := REG_INIT_C;
    end if;

    rin <= v;

    axiWriteSlave <= r.axiWriteSlave;
    axiReadSlave  <= r.axiReadSlave;

  end process comb;

  seq : process (axiClk) is
  begin
    if (rising_edge(axiClk)) then
      r <= rin after TPD_G;
    end if;
  end process seq;

  Master_3 : entity work.Max11202Master
    generic map (
      TPD_G                => TPD_G,
      CLK_PERIOD_G         => CLK_PERIOD_G,          -- 8.0E-9,
      SERIAL_SCLK_PERIOD_G => SERIAL_SCLK_PERIOD_G)  --ite(SIMULATION_G, 100.0E-9, 100.0E-6))
    port map (
      clk       => axiClk,
      Rst       => axiRst,
      rdDataA   => rdData(0),
      rdDataB   => rdData(1),
      rdDataC   => rdData(2),
      StartConv => StartConv,
      Sclk      => coreSclk,
      Sdin      => coreSDin
      );
end architecture rtl;
