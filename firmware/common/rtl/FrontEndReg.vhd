-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      FrontEndReg.vhd - 
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 7/25/2017 1:03:24 PM
--      Last change: JO 7/25/2017 2:57:13 PM
--
entity FrontEndReg is
  generic (
    TPD_G            : TPD_G,
    AXI_ERROR_RESP_G : AXI_ERROR_RESP_G
    );
  port (

-- Slave AXI-Lite Interface
    axiLiteClk     : in  sl;
    axiLiteRst     : in  sl;
    axiReadMaster  : in  AxiLiteReadMasterType;
    axiReadSlave   : out AxiLiteReadSlaveType;
    axiWriteMaster : in  AxiLiteWriteMasterType;
    axiWriteSlave  : out AxiLiteWriteSlaveType;


-- Ion Pump Control Board Mode bits
    iMode : in sl;                      -- HVPS in Current Limit Mode
    vMode : in sl;                      -- HVPS in Voltage Limit Mode
    pMode : in sl;                      -- HVPS in Power Limit Mode

-- Ion Pump Enable
    enable : out sl                     -- Enable HVPS
    );
end entity FrontEndReg;

architecture Behavioral of FrontEndReg is

  signal modes : slv(2 downto 0);

  type RegType is record
    modeBits  : slv(2 downto 0);
    enableBit : sl
  end record RegType;

  constant REG_INIT_C : RegType := (
    modeBits                    <= "000";
    enableBit                   <= '0'
    );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;


begin

  modes  <= pMode & vMode & iMode;
  enable <= r.enablebit;

  comb : process (r, axilRst, axilReadMaster, axilWriteMaster, modes) is
    variable v      : RegType;
    variable axilEp : AxiLiteEndpointType;
  begin
    v := r;

    axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

	 axiSlaveRegisterR(axilEp, X"00", 1, modes);			-- 3 mode bits in bits 3-1
    axiSlaveRegister(axilEp, X"00", 0, v.enableBit);  -- enable bit in bit 0

    axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave);

    if (axiLiteRst = '1') then
      v := REG_INIT_C;
    end if;

    rin <= v;

  end process;

  seq : process (axiLiteClk) is
  begin
    if (rising_edge(axiLiteClk) then
      r <= rin after TPD_G;
    end if;
  end process seq;

end Behavioral;

