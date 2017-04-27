-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--	lsst-ion-pump-ps-contoller.vhd - 
--
--	Copyright(c) SLAC National Accelerator Laboratory 2000
--
--	Author: Jeff Olsen
--	Created on: 4/20/2017 2:04:46 PM
--	Last change: JO 4/27/2017 9:10:19 AM
--
-------------------------------------------------------------------------------
-- File       : lsst-ion-pump-ps-contoller.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-04
-- Last update: 2017-02-07
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
	TPD_G		 		: time := 1 ns;
	BUILD_INFO_G 	: BuildInfoType
	);
port (
	Reset_n 	: in sl;

-- MGT Ethernet/UDP
	MGT_Clk_p 	: in sl;
	MGT_Clk_m 	: in sl;
	TX0_p			: out sl;
	TX0_m			: out sl;
	RX0_p			: in sl;
	Rx0_m			: in sl;

-- Boot Prom IO
	Boot_Sck		: out sl;
	Boot_D		: out slv(3 downto 0);
	Boot_CS_n	: out sl;

-- Scratch Pad Prom
	Prom_Scl		: in sl;
	Prom_Sda		: in sl;

-- Ion Pump Control Board ADC SPI Interfaces
	I_Mon_Din	: in slv(5 downto 0); 	-- Serial in from Current Mon ADC
	V_Mon_Din	: in slv(5 downto 0); 	-- Serial in from Voltage Mon ADC
	P_Mon_Din	: in slv(5 downto 0); 	-- Serial in from Power Mon ADC  
	ADC_SClk		: out slv(5 downto 0);	-- Clock for Monitor ADCs

-- Ion Pump Control Board ADC SPI Interfaces
	DAC_Dout		: out slv(5 downto 0);	-- Serial out for Setpoint DACs
	DAC_SClk		: out slv(5 downto 0);	-- Clock for the Setpoint DACs
	I_Prog_CS_n	: out sl;					-- Chip Enable for Current DAC
	V_Prog_CS_n	: out sl;					-- Chip Enable for Voltage DAC
	P_Prog_CS_n	: out sl;					-- Chip Enable for Power DAC

-- Ion Pump Control Board Mode bits
	I_Mode		: in slv(5 downto 0);	-- HVPS in Current Limit Mode
	V_Mode		: in slv(5 downto 0);	-- HVPS in Voltage Limit Mode
	P_Mode		: in slv(5 downto 0);	-- HVPS in Power Limit Mode

-- Ion Pump Enable
	Enable		: out slv(5 downto 0)	-- Enable HVPS
);
end IonPumpController;

architecture top_level of IonPumpController is

signal SysClk						: slv(0 downto 0);
signal SysReset 					: slv(0 downto 0);
signal fpgaReload					: sl;
signal fpgaReloadAddr 			: slv(31 downto 0);

signal txMasters 					: AxiStreamMasterArray(0 downto 0);
signal txSlaves  					: AxiStreamSlaveArray(0 downto 0);
signal rxMasters 					: AxiStreamMasterArray(0 downto 0);
signal rxSlaves  					: AxiStreamSlaveArray(0 downto 0);

constant NUM_AXI_MASTERS_C 	: natural := 4;
constant ETHERNET_INDEX_C  	: natural := 0;	-- Ethernet UDP Interface
constant VERSION_INDEX_C		: natural := 1;	-- Version Interface
constant BOOT_PROM_INDEX_C    : natural := 2;	-- Boot PROM
constant ION_CONTROL_INDEX_C  : natural := 3;	-- Ion Pump Control Registers and SPI

constant ETHERNET_BASE_ADDR_C  		: slv(31 downto 0) := x"0000_0000" + AXIL_BASE_ADDR_G;
constant VERSION_BASE_ADDR_C			: slv(31 downto 0) := x"0001_0000" + AXIL_BASE_ADDR_G;
constant BOOT_PROM_BASE_ADDR_C    	: slv(31 downto 0) := x"0002_0000" + AXIL_BASE_ADDR_G;
constant ION_CONTROL_BASE_ADDR_C  	: slv(31 downto 0) := x"0003_0000" + AXIL_BASE_ADDR_G;

constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) :=
(
	ETHERNET_INDEX_C	 => (
		baseAddr		 => ETHERNET_BASE_ADDR_C,
		addrBits		 => 16,
		connectivity => x"FFFF"),
	VERSION_INDEX_C	 => (
		baseAddr		 => VERSION_BASE_ADDR_C,
		addrBits		 => 16,
		connectivity => x"FFFF"),
	BOOT_PROM_INDEX_C	 => (
		baseAddr		 => BOOT_PROM_BASE_ADDR_C,
		addrBits		 => 16,
		connectivity => x"FFFF"),
	ION_CONTROL_INDEX_C	 => (
		baseAddr		 => ION_CONTROL_BASE_ADDR_C,
		addrBits		 => 16,
		connectivity => x"FFFF")
	);


signal axilWriteMasters 		: AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
signal axilWriteSlaves  		: AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
signal axilReadMasters  		: AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
signal axilReadSlaves   		: AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

begin

Boot_D(3 downto 1) <= (Others => '0');



u_Ethernet :  entity work.GigEthGtp7Wrapper
generic map (
	TPD_G						=> TPD_G,
	NUM_LANE_G			 	=> 1,
-- Clocking Configurations
	USE_GTREFCLK_G		 	=> false,	--	 FALSE: gtClkP/N,	 TRUE: gtRefClk
	CLKIN_PERIOD_G		 	=> 8.0,
	DIVCLK_DIVIDE_G	 	=> 1,
	CLKFBOUT_MULT_F_G	 	=> 8.0,
	CLKOUT0_DIVIDE_F_G 	=> 8.0,
-- AXI-Lite Configurations
	EN_AXI_REG_G		 	=> false,
	AXI_ERROR_RESP_G	 	=> AXI_RESP_SLVERR_C,
-- AXI Streaming Configurations
	AXIS_CONFIG_G		 	=> (others => AXI_STREAM_CONFIG_INIT_C)
)
port map (
-- Local Configurations
	localMac					=> (others => MAC_ADDR_INIT_C),
-- Streaming DMA Interface
	dmaClk					=> SysClk,
	dmaRst					=> SysReset,
	dmaIbMasters			=> rxMasters,
	dmaIbSlaves				=> rxSlaves,
	dmaObMasters			=> txMasters, 
	dmaObSlaves				=> txSlaves,
-- Slave AXI-Lite Interface
	axiLiteClk				=> SysClk,
	axiLiteRst				=> SysReset,
	axiLiteReadMasters  	=>	axilReadMasters(ETHERNET_C downto ETHERNET_C),
	axiLiteReadSlaves	  	=>	axilReadSlaves(ETHERNET_C downto ETHERNET_C),
	axiLiteWriteMasters 	=>	axilWriteMasters(ETHERNET_C downto ETHERNET_C),
	axiLiteWriteSlaves  	=>	axilWriteSlaves(ETHERNET_C downto ETHERNET_C),
-- Misc. Signals
	extRst					=> SysReset(0),
	phyClk					=> SysClk(0),
	phyRst					=> open,
	phyReady				  	=> open,
	sigDet				  	=> "0",
-- MGT Clock Port (156.25 MHz or 312.5 MHz)
	gtRefClk				  	=> '0',
	gtClkP				  	=> MGT_Clk_p,
	gtClkN				  	=> MGT_Clk_m,
-- MGT Ports
	gtTxP(0)					=> TX0_p,
	gtTxN(0)					=> TX0_m,
	gtRxP(0)					=> RX0_p,
	gtRxN(0)					=> RX0_m
);

u_Version : entity work.AxiVersion
generic map (
	TPD_G					 => TPD_G,
	BUILD_INFO_G		 => BUILD_INFO_G,
--	SIM_DNA_VALUE_G	 => X"000000000000000000000000",
	AXI_ERROR_RESP_G	 => AXI_RESP_DECERR_C,
	DEVICE_ID_G			 => (others => '0'),
	CLK_PERIOD_G		 => 8.0E-9,  			-- units of seconds
	XIL_DEVICE_G		 => "7SERIES",  		-- Either "7SERIES" or "ULTRASCALE"
	EN_DEVICE_DNA_G	 => true,
	EN_DS2411_G			 => true,
	EN_ICAP_G			 => true,
	USE_SLOWCLK_G		 => true,
	BUFR_CLK_DIV_G		 => 8,
	AUTO_RELOAD_EN_G	 => false,
	AUTO_RELOAD_TIME_G => 10.0,	-- units of seconds
	AUTO_RELOAD_ADDR_G => (others => '0')
	)
port map (
-- AXI-Lite Interface
	axiClk					=>	SysClk(0),
	axiRst					=> SysReset(0),
	axiLiteReadMaster  	=>	axilReadMasters(VERSION_INDEX_C),
	axiLiteReadSlave	  	=>	axilReadSlaves(VERSION_INDEX_C),
	axiLiteWriteMaster 	=>	axilWriteMasters(VERSION_INDEX_C),
	axiLiteWriteSlave  	=>	axilWriteSlaves(VERSION_INDEX_C),
-- Optional: Master Reset
	masterReset				=> open,
-- Optional: FPGA Reloading Interface
	fpgaEnReload			=> '1',
	fpgaReload				=> FpgaReload,
	fpgaReloadAddr 		=> FpgaReloadAddr,
	upTimeCnt				=> open,
-- Optional: Serial Number outputs
	slowClk					=> SysClk(0),
	dnaValueOut				=> open,
	fdValueOut				=> open,
-- Optional: user values
	userValues				=> (others => X"00000000"),
-- Optional: DS2411 interface
	fdSerSdio				=> 'Z')
);

u_Micron : entity work.AxiMicronN25QCore
   generic map (
      TPD_G            => 1 ns,
      MEM_ADDR_MASK_G  => x"00000000",
      AXI_CLK_FREQ_G   => 200.0E+6,  -- units of Hz
      SPI_CLK_FREQ_G   => 25.0E+6,   -- units of Hz
      PIPE_STAGES_G    => 0,
--      AXI_CONFIG_G     => ssiAxiStreamConfig(4),
      AXI_ERROR_RESP_G => AXI_RESP_SLVERR_C)
   port map (
      -- FLASH Memory Ports
      csL            => Boot_CS_n,
      sck            => Boot_SCk,
      mosi           => Boot_D(0),
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
      axiClk        	=> SysClk(0),
      axiRst         => SysReset(0)
		);

u_Iprog : entity work.Iprog
   generic map (
      TPD_G         => TPD_G,
      USE_SLOWCLK_G => true,
      XIL_DEVICE_G  => "7SERIES")
   port map (
      slowClk     => SysClk(0),
      clk         => SysClk(0),
      rst         => SysReset(0),
      start       => FpgaReload,
      bootAddress => FpgaReloadAddr
		);

u_IonPumpApp : entity work.IonPumpApp
generic map (
	TPD_G						=> TPD_G,
	AXIL_BASE_ADDR_G 		=> AXI_CONFIG_C(ION_CONTROL_INDEX_C).baseAddr,
	AXI_ERROR_RESP_G 		=> AXI_ERROR_RESP_G
)
port map (

-- Slave AXI-Lite Interface
	axiLiteClk				=> SysClk,
	axiLiteRst				=> SysReset,
	axiLiteReadMaster  	=>	axilReadMasters(ION_CONTROL_INDEX_C),
	axiLiteReadSlave	  	=>	axilReadSlaves(ION_CONTROL_INDEX_C),
	axiLiteWriteMaster 	=>	axilWriteMasters(ION_CONTROL_INDEX_C),
	axiLiteWriteSlave  	=>	axilWriteSlaves(ION_CONTROL_INDEX_C),

--	Controller IO
-- Ion Pump Control Board ADC SPI Interfaces
	I_Mon_Din				=> I_Mon_Din,		-- Serial in from Current Mon ADC
	V_Mon_Din				=> V_Mon_Din,		-- Serial in from Voltage Mon ADC
	P_Mon_Din				=> P_Mon_Din,		-- Serial in from Power Mon ADC
	ADC_SClk					=> ADC_SClk,		-- Clock for Monitor ADCs

-- Ion Pump Control Board ADC SPI Interfaces
	DAC_Dout					=> DAC_Dout,		-- Serial out for Setpoint DACs
	DAC_SClk					=> DAC_SCLK,		-- Clock for the Setpoint DACs
	I_Prog_CS_n				=> I_Prog_Cs_n,	-- Chip Enable for Current DAC
	V_Prog_CS_n				=> V_Prog_Cs_n,	-- Chip Enable for Voltage DAC
	P_Prog_CS_n				=> P_Prog_Cs_n,	-- Chip Enable for Power DAC

-- Ion Pump Control Board Mode bits
	I_Mode					=> I_Mode,			-- HVPS in Current Limit Mode
	V_Mode					=> V_Mode,			-- HVPS in Voltage Limit Mode
	P_Mode					=> P_Mode,			-- HVPS in Power Limit Mode

-- Ion Pump Enable
	Enable					=> Enable			-- Enable HVPS
);


end top_level;
