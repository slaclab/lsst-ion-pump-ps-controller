-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--	Max5216Axil.vhd - 
--
--	Copyright(c) SLAC National Accelerator Laboratory 2000
--
--	Author: Jeff Olsen
--	Created on: 5/1/2018 8:50:23 AM
--	Last change: JO 5/1/2018 9:02:00 AM
--
-------------------------------------------------------------------------------
-- File       : Max5216Axil.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-01-12
-- Last update: 2018-02-01
-------------------------------------------------------------------------------
-- Description: Axi lite interface for a single chip "generic SPI master"
--                For multiple chips on single bus connect multiple cores
--                to multiple AXI crossbar slaves and use Chip select outputs
--                (coreCsb) to multiplex select the addressed outputs (coreSDout and
--                coreSclk).
--                The coreCsb is active low. And active only if the corresponding 
--                Axi Crossbar Slave is addressed.
--                DATA_SIZE_G - Corresponds to total read or write command size (not just data size).
--                              Example: DATA_SIZE_G = 24
--                                       1-bit command, 15-bit address word and 8-bit data
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity Max5216Axil is
   generic (
      TPD_G             : time            := 1 ns;
      ADDRESS_SIZE_G    : natural         := 15;
      DATA_SIZE_G       : natural         := 8;
      MODE_G            : string          := "WO";  -- Or "WO" (write only),  "RO" (read only)
      CPHA_G            : sl              := '0';
      CPOL_G            : sl              := '1';
      CLK_PERIOD_G      : real            := 6.4E-9;
      SPI_SCLK_PERIOD_G : real            := 100.0E-6;
      SPI_NUM_CHIPS_G   : positive        := 1
      );
   port (
      axiClk : in sl;
      axiRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      coreSclk  : out sl;
      coreSDin  : in  sl;
      coreSDout : out sl;
      coreCsb   : out sl;  -- coreCsb is for legacy firmware without SPI_NUM_CHIPS_G generic
      coreMCsb  : out slv(SPI_NUM_CHIPS_G-1 downto 0)
      );
end entity Max5216Axil;

architecture rtl of Max5216Axil is

   -- AdcCore Outputs
   constant PACKET_SIZE_C : positive := ite(MODE_G = "RW", 1, 0) + ADDRESS_SIZE_G + DATA_SIZE_G;  -- "1+" For R/W command bit
   constant CHIP_BITS_C   : integer  := log2(SPI_NUM_CHIPS_G);

   signal rdData : slv(PACKET_SIZE_C-1 downto 0);
   signal rdEn   : sl;

   type StateType is (WAIT_AXI_TXN_S, WAIT_CYCLE_S, WAIT_SPI_TXN_DONE_S);

   -- Registers
   type RegType is record
      state         : StateType;
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      -- Adc Core Inputs
      wrData        : slv(PACKET_SIZE_C-1 downto 0);
      chipSel       : slv(CHIP_BITS_C-1 downto 0);
      wrEn          : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state         => WAIT_AXI_TXN_S,
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      wrData        => (others => '0'),
      chipSel       => (others => '0'),
      wrEn          => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   signal csb : slv(SPI_NUM_CHIPS_G-1 downto 0);

begin

   comb : process (axiReadMaster, axiRst, axiWriteMaster, r, rdData, rdEn) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      case (r.state) is
         when WAIT_AXI_TXN_S =>

            if (axiStatus.writeEnable = '1') then
                  -- Data
						-- 01, write through
						-- data[15:0]
						-- zero filled
                  v.wrData(DATA_SIZE_G-1 downto 0) := "01" & axiWriteMaster.wdata(15 downto 0) & "000000";
                  -- Chip select
                  v.chipSel                        := axiWriteMaster.awaddr(CHIP_BITS_C+ADDRESS_SIZE_G+1 downto 2+ADDRESS_SIZE_G);
                  v.wrEn                           := '1';
                  v.state                          := WAIT_CYCLE_S;
            end if;

            if (axiStatus.readEnable = '1') then
                  axiSlaveReadResponse(v.axiReadSlave, AXI_RESP_DECERR_C);
            end if;

         when WAIT_CYCLE_S =>
            -- Wait for rdEn to drop
            if (rdEn = '0') then
               v.wrEn  := '0';
               v.state := WAIT_SPI_TXN_DONE_S;
            end if;

         when WAIT_SPI_TXN_DONE_S =>

            if (rdEn = '1') then
               v.state := WAIT_AXI_TXN_S;
               
               if (MODE_G = "WO" or (MODE_G = "RW" and r.wrData(PACKET_SIZE_C-1) = '0')) then
                  axiSlaveWriteResponse(v.axiWriteSlave);
               else
                  v.axiReadSlave.rdata                         := (others => '0');
                  v.axiReadSlave.rdata(DATA_SIZE_G-1 downto 0) := rdData(DATA_SIZE_G-1 downto 0);
                  axiSlaveReadResponse(v.axiReadSlave);
               end if;
            end if;

         when others => null;
      end case;

      -- Check if single access
      if (SPI_NUM_CHIPS_G = 1) then
         v.chipSel := (others => '0');
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

   SpiMaster_1 : entity surf.SpiMaster
      generic map (
         TPD_G             => TPD_G,
         NUM_CHIPS_G       => SPI_NUM_CHIPS_G,
         DATA_SIZE_G       => PACKET_SIZE_C,
         CPHA_G            => CPHA_G,
         CPOL_G            => CPOL_G,
         CLK_PERIOD_G      => CLK_PERIOD_G,
         SPI_SCLK_PERIOD_G => SPI_SCLK_PERIOD_G)
      port map (
         clk     => axiClk,
         sRst    => axiRst,
         chipSel => r.chipSel,
         wrEn    => r.wrEn,
         wrData  => r.wrData,
         rdEn    => rdEn,
         rdData  => rdData,
         spiCsL  => csb,
         spiSclk => coreSclk,
         spiSdi  => coreSDout,
         spiSdo  => coreSDin);

   coreCsb  <= csb(0);
   coreMCsb <= csb;

end architecture rtl;
