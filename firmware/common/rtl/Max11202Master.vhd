-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      Max11202Master.vhd - 
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 7/18/2017 3:10:01 PM
--      Last change: JO 4/27/2018 9:08:38 AM
--
-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Max11202Master.vhd
-- From
-- File       : SpiMaster.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-05-24
-- Last update: 2018-04-19
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
--use ieee.math_real.all;
use work.StdRtlPkg.all;

entity max11202Master is
  generic (
    TPD_G                : time := 1 ns;
    CLK_PERIOD_G         : real := 8.0E-9;
    SERIAL_SCLK_PERIOD_G : real := 1.0E-6);  -- 1 MHz
  port (
    --Global Signals
    clk       : in  sl;
    Rst       : in  sl;
    -- Parallel interface
    StartConv : in  sl;
    rdDataA   : out slv(31 downto 0);
    rdDataB   : out slv(31 downto 0);
    rdDataC   : out slv(31 downto 0);
    Sclk      : out sl;
    Sdin      : in  slv(2 downto 0)
    );
end max11202Master;

architecture rtl of max11202Master is

  constant SERIAL_CLK_PERIOD_DIV2_CYCLES_C : integer := integer(SERIAL_SCLK_PERIOD_G / (2.0*CLK_PERIOD_G));
  constant SCLK_COUNTER_SIZE_C             : integer := bitSize(SERIAL_CLK_PERIOD_DIV2_CYCLES_C);


  -- Types
  type data24 is array (2 downto 0) of slv(23 downto 0);

  type StateType is (
    IDLE_S,
    WAIT_READY_S,
    SHIFT_S,
    SAMPLE_S,
    DONE_S);

  type RegType is record
    state       : StateType;
    syncSdin    : slv(2 downto 0);
    rdData      : data24;
	 rdDataA		: slv(31 downto 0);
	 rdDataB		: slv(31 downto 0);
	 rdDataC  : slv(31 downto 0);
    dataCounter : slv(25 downto 0);
    sclkCounter : slv(SCLK_COUNTER_SIZE_C-1 downto 0);
    Sclk        : sl;
  end record RegType;

  constant REG_INIT_C : RegType := (
    state       => IDLE_S,
    syncSdin    => "000",
    rdData      => (others => x"0000000"),
	 rdDataA     => (others => '0'),
	 rdDataB     => (others => '0'),
	 rdDataC     => (others => '0'),
    dataCounter => (others => '0'),
    sclkCounter => (others => '0'),
    Sclk        => '0'
    );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

begin

  comb : process (r, Rst, sdin, startConv) is
    variable v : RegType;
  begin
    v          := r;
    v.SyncSdin := Sdin;

    case (r.state) is
      when IDLE_S =>
        v.dataCounter := (others => '0');
        v.sclkCounter := (others => '0');
        v.rdData(0)   := (others => '0');
        v.rdData(1)   := (others => '0');
        v.rdData(2)   := (others => '0');

        if (StartConv = '1') then
          -- Exit from sleep state by dropping clock, start convert
          v.Sclk  := '0';
          v.state := WAIT_READY_S;
        end if;

      when WAIT_READY_S =>
        -- wait for all three ADC to be ready
        if (r.SyncSdin = "000") then    -- All ADCs are ready
          v.state := Shift_S;
        end if;

      when SHIFT_S =>
        -- Wait half a clock period then shift out the next data bit
        v.sclkCounter := r.sclkCounter + 1;
        if (r.sclkCounter = SERIAL_CLK_PERIOD_DIV2_CYCLES_C) then
          v.sclkCounter := (others => '0');
          v.Sclk        := '1';
          v.state       := SAMPLE_S;
        end if;


      when SAMPLE_S =>
        -- Wait half a clock period then sample the next data bit
        v.sclkCounter := r.sclkCounter + 1;
        if (r.sclkCounter = SERIAL_CLK_PERIOD_DIV2_CYCLES_C) then
          v.sclkCounter := (others => '0');
          v.rdData(0)   := r.rdData(0)(22 downto 0) & SDin(0);
          v.rdData(1)   := r.rdData(1)(22 downto 0) & SDin(1);
          v.rdData(2)   := r.rdData(2)(22 downto 0) & SDin(2);

          v.dataCounter := r.dataCounter + 1;
          if (r.dataCounter = 23) then
            v.Sclk  := '1';
            v.state := DONE_S;
          else
            v.Sclk  := '0';
            v.state := SHIFT_S;

          end if;
        end if;

      when DONE_S =>
        v.sclkCounter := r.sclkCounter + 1;
        if (r.sclkCounter = SERIAL_CLK_PERIOD_DIV2_CYCLES_C) then
          v.sclkCounter := (others => '0');
			 -- sign extend 24 bits to 32 bits
          v.rdDataA       := r.rdData(0)(23) & r.rdData(0)(23) & r.rdData(0)(23) & r.rdData(0)(23) &
									  r.rdData(0)(23) & r.rdData(0)(23) & r.rdData(0)(23) & r.rdData(0)(23) &
									  r.rdData(0);
          v.rdDataB       := r.rdData(1)(23) & r.rdData(1)(23) & r.rdData(1)(23) & r.rdData(1)(23) &
									  r.rdData(1)(23) & r.rdData(1)(23) & r.rdData(1)(23) & r.rdData(1)(23) &
									  r.rdData(1);
          v.rdDataC       := r.rdData(2)(23) & r.rdData(2)(23) & r.rdData(2)(23) & r.rdData(2)(23) &
									  r.rdData(2)(23) & r.rdData(2)(23) & r.rdData(2)(23) & r.rdData(2)(23) &
									  r.rdData(2);
          v.state       := IDLE_S;
        end if;
      when others => null;
    end case;

	 rdDataA <= r.rdDataA;
	 rdDataB <= r.rdDataB;
	 rdDataC <= r.rdDataC;

    if (Rst = '1') then
      v := REG_INIT_C;
    end if;

    rin <= v;

    Sclk <= r.Sclk;

  end process comb;

  seq : process (clk) is
  begin
    if (rising_edge(clk)) then
      r <= rin after TPD_G;
    end if;
  end process seq;

end rtl;
