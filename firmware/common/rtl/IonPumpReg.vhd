-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      IonPumpReg.vhd -
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 7/25/2017 1:03:24 PM
--      Last change: JO 5/1/2018 4:13:17 PM
--
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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity IonPumpReg is
  generic (
    TPD_G : time := 1 ns
    );
  port (
    -- AXI-Lite Interface
    axilClk         : in  sl;
    axilRst         : in  sl;
    axilReadMaster  : in  AxiLiteReadMasterType;
    axilReadSlave   : out AxiLiteReadSlaveType;
    axilWriteMaster : in  AxiLiteWriteMasterType;
    axilWriteSlave  : out AxiLiteWriteSlaveType;

-- Ion Pump Control Board Mode bits
    iMode : in slv(8 downto 0);         -- HVPS in Current Limit Mode
    vMode : in slv(8 downto 0);         -- HVPS in Voltage Limit Mode
    pMode : in slv(8 downto 0);         -- HVPS in Power Limit Mode

-- Ion Pump Enable
    Enable : out slv(8 downto 0)        -- Enable HVPS
    );
end entity IonPumpReg;

architecture Behavioral of IonPumpReg is

  type RegType is record
    ChannelEn      : slv(8 downto 0);
    axilReadSlave  : AxiLiteReadSlaveType;
    axilWriteSlave : AxiLiteWriteSlaveType;
  end record;

  constant REG_INIT_C : RegType := (
    ChannelEn      => (others => '0'),
    axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

begin

  comb : process (iMode, vMode, pMode, axilReadMaster, axilRst,
                  axilWriteMaster, r) is
    variable v      : RegType;
    variable axilEp : AxiLiteEndpointType;
  begin
    -- Latch the current value
    v := r;
    -- Determine the transaction type
    axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

    -- Register Mapping
    axiSlaveRegister(axilEp, X"00", 0, v.ChannelEn);  -- Register 0 Enable
    axiSlaveRegisterR(axilEp, X"04", 0, not(iMode));       -- IMode Status
    axiSlaveRegisterR(axilEp, X"08", 0, not(vMode));       -- VMode Status
    axiSlaveRegisterR(axilEp, X"0C", 0, not(pMode));       --  PMode Status

    -- Closeout the txn
    axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave);

    -- Reset
    if (axilRst = '1') then
      v := REG_INIT_C;
    end if;

    -- Register the variable for next clock cycle
    rin <= v;

    -- Outputs 
    axilReadSlave  <= r.axilReadSlave;
    axilWriteSlave <= r.axilWriteSlave;
    Enable         <= r.ChannelEn;

  end process;

  seq : process (axilClk) is
  begin
    if (rising_edge(axilClk)) then
      r <= rin after TPD_G;
    end if;
  end process seq;

end Behavioral;

