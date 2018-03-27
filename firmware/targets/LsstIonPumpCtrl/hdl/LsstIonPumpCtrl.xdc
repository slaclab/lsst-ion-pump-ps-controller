##############################################################################
## This file is part of 'LSST Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LSST Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######################
## Application Ports ##
#######################

set_property -dict { PACKAGE_PIN D22    IOSTANDARD xxx } [get_ports { IONPUMP_EN_N}]


set_property -dict { PACKAGE_PIN Y7     IOSTANDARD LVCMOS33 } [get_ports { dacSclk[8]}]
set_property -dict { PACKAGE_PIN P6     IOSTANDARD LVCMOS33 } [get_ports { dacSclk[7]}]
set_property -dict { PACKAGE_PIN F3     IOSTANDARD LVCMOS33 } [get_ports { dacSclk[6]}]
set_property -dict { PACKAGE_PIN U1     IOSTANDARD LVCMOS33 } [get_ports { dacSclk[5]}]
set_property -dict { PACKAGE_PIN B2     IOSTANDARD LVCMOS33 } [get_ports { dacSclk[4]}]
set_property -dict { PACKAGE_PIN A16    IOSTANDARD LVCMOS33 } [get_ports { dacSclk[3]}]
set_property -dict { PACKAGE_PIN AB7    IOSTANDARD LVCMOS33 } [get_ports { dacSclk[2]}]
set_property -dict { PACKAGE_PIN AA15   IOSTANDARD LVCMOS33 } [get_ports { dacSclk[1]}]
set_property -dict { PACKAGE_PIN G22    IOSTANDARD LVCMOS33 } [get_ports { dacSclk[0]}]

set_property -dict { PACKAGE_PIN U7     IOSTANDARD LVCMOS33 } [get_ports { adcSClk[8]}]
set_property -dict { PACKAGE_PIN L6     IOSTANDARD LVCMOS33 } [get_ports { adcSClk[7]}]
set_property -dict { PACKAGE_PIN E3     IOSTANDARD LVCMOS33 } [get_ports { adcSClk[6]}]
set_property -dict { PACKAGE_PIN R2     IOSTANDARD LVCMOS33 } [get_ports { adcSClk[5]}]
set_property -dict { PACKAGE_PIN D1     IOSTANDARD LVCMOS33 } [get_ports { adcSClk[4]}]
set_property -dict { PACKAGE_PIN B17    IOSTANDARD LVCMOS33 } [get_ports { adcSClk[3]}]
set_property -dict { PACKAGE_PIN AA6    IOSTANDARD LVCMOS33 } [get_ports { adcSClk[2]}]
set_property -dict { PACKAGE_PIN AA14   IOSTANDARD LVCMOS33 } [get_ports { adcSClk[1]}]
set_property -dict { PACKAGE_PIN H22    IOSTANDARD LVCMOS33 } [get_ports { adcSClk[0]}]

set_property -dict { PACKAGE_PIN AB21   IOSTANDARD LVCMOS33 } [get_ports { extRstL}]

set_property -dict { PACKAGE_PIN V17    IOSTANDARD LVCMOS33 } [get_ports { promSda}]
set_property -dict { PACKAGE_PIN AB20   IOSTANDARD LVCMOS33 } [get_ports { promScl}]

#set_property -dict { PACKAGE_PIN L12    IOSTANDARD LVCMOS33 } [get_ports { BOOT_SCK}]
#set_property -dict { PACKAGE_PIN P22    IOSTANDARD LVCMOS33 } [get_ports { BOOT_D[O]}]
#set_property -dict { PACKAGE_PIN R22    IOSTANDARD LVCMOS33 } [get_ports { BOOT_D[1]}]
#set_property -dict { PACKAGE_PIN P21    IOSTANDARD LVCMOS33 } [get_ports { BOOT_D[2]}]
#set_property -dict { PACKAGE_PIN R21    IOSTANDARD LVCMOS33 } [get_ports { BOOT_D[3]}]

set_property -dict { PACKAGE_PIN P22    IOSTANDARD LVCMOS33 } [get_ports { bootMosi}]
set_property -dict { PACKAGE_PIN R22    IOSTANDARD LVCMOS33 } [get_ports { bootMiso}]
set_property -dict { PACKAGE_PIN T19    IOSTANDARD LVCMOS33 } [get_ports { bootCsL}]

#set_property -dict { PACKAGE_PIN F10    IOSTANDARD LVCMOS33 } [get_ports { ethClkP}]
#set_property -dict { PACKAGE_PIN E10    IOSTANDARD LVCMOS33 } [get_ports { ethClkN}]

set_property -dict { PACKAGE_PIN W4     IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[8]}]
set_property -dict { PACKAGE_PIN P4     IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[7]}]
set_property -dict { PACKAGE_PIN J4     IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[6]}]
set_property -dict { PACKAGE_PIN T1     IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[5]}]
set_property -dict { PACKAGE_PIN B1     IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[4]}]
set_property -dict { PACKAGE_PIN B15    IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[3]}]
set_property -dict { PACKAGE_PIN AA8    IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[2]}]
set_property -dict { PACKAGE_PIN AB16   IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[1]}]
set_property -dict { PACKAGE_PIN F21    IOSTANDARD LVCMOS33 } [get_ports { vProgCsL[0]}]


set_property -dict { PACKAGE_PIN Y1     IOSTANDARD LVCMOS33 } [get_ports { vMonDin[8]}]
set_property -dict { PACKAGE_PIN L5     IOSTANDARD LVCMOS33 } [get_ports { vMonDin[7]}]
set_property -dict { PACKAGE_PIN H5     IOSTANDARD LVCMOS33 } [get_ports { vMonDin[6]}]
set_property -dict { PACKAGE_PIN N2     IOSTANDARD LVCMOS33 } [get_ports { vMonDin[5]}]
set_property -dict { PACKAGE_PIN F1     IOSTANDARD LVCMOS33 } [get_ports { vMonDin[4]}]
set_property -dict { PACKAGE_PIN A20    IOSTANDARD LVCMOS33 } [get_ports { vMonDin[3]}]
set_property -dict { PACKAGE_PIN AB3    IOSTANDARD LVCMOS33 } [get_ports { vMonDin[2]}]
set_property -dict { PACKAGE_PIN AB11   IOSTANDARD LVCMOS33 } [get_ports { vMonDin[1]}]
set_property -dict { PACKAGE_PIN K22    IOSTANDARD LVCMOS33 } [get_ports { vMonDin[0]}]

set_property -dict { PACKAGE_PIN V4     IOSTANDARD LVCMOS33 } [get_ports { vMode[8]}]
set_property -dict { PACKAGE_PIN P5     IOSTANDARD LVCMOS33 } [get_ports { vMode[7]}]
set_property -dict { PACKAGE_PIN K4     IOSTANDARD LVCMOS33 } [get_ports { vMode[6]}]
set_property -dict { PACKAGE_PIN M2     IOSTANDARD LVCMOS33 } [get_ports { vMode[5]}]
set_property -dict { PACKAGE_PIN E2     IOSTANDARD LVCMOS33 } [get_ports { vMode[4]}]
set_property -dict { PACKAGE_PIN A19    IOSTANDARD LVCMOS33 } [get_ports { vMode[3]}]
set_property -dict { PACKAGE_PIN AA4    IOSTANDARD LVCMOS33 } [get_ports { vMode[2]}]
set_property -dict { PACKAGE_PIN AB12   IOSTANDARD LVCMOS33 } [get_ports { vMode[1]}]
set_property -dict { PACKAGE_PIN K21    IOSTANDARD LVCMOS33 } [get_ports { vMode[0]}]

#set_property -dict { PACKAGE_PIN B4     IOSTANDARD LVCMOS33 } [get_ports { ethTxP}]
#set_property -dict { PACKAGE_PIN A4     IOSTANDARD LVCMOS33 } [get_ports { ethTxN}]
#set_property -dict { PACKAGE_PIN B8     IOSTANDARD LVCMOS33 } [get_ports { ethRxP}]
#set_property -dict { PACKAGE_PIN A8     IOSTANDARD LVCMOS33 } [get_ports { ethRxN}]

set_property -dict { PACKAGE_PIN V5     IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[8]}]
set_property -dict { PACKAGE_PIN M6     IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[7]}]
set_property -dict { PACKAGE_PIN L3     IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[6]}]
set_property -dict { PACKAGE_PIN R1     IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[5]}]
set_property -dict { PACKAGE_PIN C2     IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[4]}]
set_property -dict { PACKAGE_PIN B16    IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[3]}]
set_property -dict { PACKAGE_PIN AB6    IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[2]}]
set_property -dict { PACKAGE_PIN AB15   IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[1]}]
set_property -dict { PACKAGE_PIN G21    IOSTANDARD LVCMOS33 } [get_ports { pProgCsL[0]}]

set_property -dict { PACKAGE_PIN W1     IOSTANDARD LVCMOS33 } [get_ports { pMonDin[8]}]
set_property -dict { PACKAGE_PIN J6     IOSTANDARD LVCMOS33 } [get_ports { pMonDin[7]}]
set_property -dict { PACKAGE_PIN J5     IOSTANDARD LVCMOS33 } [get_ports { pMonDin[6]}]
set_property -dict { PACKAGE_PIN M1     IOSTANDARD LVCMOS33 } [get_ports { pMonDin[5]}]
set_property -dict { PACKAGE_PIN G2     IOSTANDARD LVCMOS33 } [get_ports { pMonDin[4]}]
set_property -dict { PACKAGE_PIN A21    IOSTANDARD LVCMOS33 } [get_ports { pMonDin[3]}]
set_property -dict { PACKAGE_PIN AB2    IOSTANDARD LVCMOS33 } [get_ports { pMonDin[2]}]
set_property -dict { PACKAGE_PIN AB10   IOSTANDARD LVCMOS33 } [get_ports { pMonDin[1]}]
set_property -dict { PACKAGE_PIN M22    IOSTANDARD LVCMOS33 } [get_ports { pMonDin[0]}]

set_property -dict { PACKAGE_PIN Y3     IOSTANDARD LVCMOS33 } [get_ports { pMode[8]}]
set_property -dict { PACKAGE_PIN N3     IOSTANDARD LVCMOS33 } [get_ports { pMode[7]}]
set_property -dict { PACKAGE_PIN H4     IOSTANDARD LVCMOS33 } [get_ports { pMode[6]}]
set_property -dict { PACKAGE_PIN L1     IOSTANDARD LVCMOS33 } [get_ports { pMode[5]}]
set_property -dict { PACKAGE_PIN G1     IOSTANDARD LVCMOS33 } [get_ports { pMode[4]}]
set_property -dict { PACKAGE_PIN B20    IOSTANDARD LVCMOS33 } [get_ports { pMode[3]}]
set_property -dict { PACKAGE_PIN AA3    IOSTANDARD LVCMOS33 } [get_ports { pMode[2]}]
set_property -dict { PACKAGE_PIN AA11   IOSTANDARD LVCMOS33 } [get_ports { pMode[1]}]
set_property -dict { PACKAGE_PIN L21    IOSTANDARD LVCMOS33 } [get_ports { pMode[0]}]

set_property -dict { PACKAGE_PIN Y6     IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[8]}]
set_property -dict { PACKAGE_PIN M5     IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[7]}]
set_property -dict { PACKAGE_PIN K3     IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[6]}]
set_property -dict { PACKAGE_PIN U2     IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[5]}]
set_property -dict { PACKAGE_PIN A1     IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[4]}]
set_property -dict { PACKAGE_PIN A15    IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[3]}]
set_property -dict { PACKAGE_PIN AB8    IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[2]}]
set_property -dict { PACKAGE_PIN AA16   IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[1]}]
set_property -dict { PACKAGE_PIN E22    IOSTANDARD LVCMOS33 } [get_ports { iProgCsL[0]}]

set_property -dict { PACKAGE_PIN U3     IOSTANDARD LVCMOS33 } [get_ports { iMonDin[8]}]
set_property -dict { PACKAGE_PIN L4     IOSTANDARD LVCMOS33 } [get_ports { iMonDin[7]}]
set_property -dict { PACKAGE_PIN H3     IOSTANDARD LVCMOS33 } [get_ports { iMonDin[6]}]
set_property -dict { PACKAGE_PIN P1     IOSTANDARD LVCMOS33 } [get_ports { iMonDin[5]}]
set_property -dict { PACKAGE_PIN E1     IOSTANDARD LVCMOS33 } [get_ports { iMonDin[4]}]
set_property -dict { PACKAGE_PIN B18    IOSTANDARD LVCMOS33 } [get_ports { iMonDin[3]}]
set_property -dict { PACKAGE_PIN AA5    IOSTANDARD LVCMOS33 } [get_ports { iMonDin[2]}]
set_property -dict { PACKAGE_PIN AA13   IOSTANDARD LVCMOS33 } [get_ports { iMonDin[1]}]
set_property -dict { PACKAGE_PIN J22    IOSTANDARD LVCMOS33 } [get_ports { iMonDin[0]}]

set_property -dict { PACKAGE_PIN Y4     IOSTANDARD LVCMOS33 } [get_ports { iMode[8]}]
set_property -dict { PACKAGE_PIN M3     IOSTANDARD LVCMOS33 } [get_ports { iMode[7]}]
set_property -dict { PACKAGE_PIN G4     IOSTANDARD LVCMOS33 } [get_ports { iMode[6]}]
set_property -dict { PACKAGE_PIN P2     IOSTANDARD LVCMOS33 } [get_ports { iMode[5]}]
set_property -dict { PACKAGE_PIN D2     IOSTANDARD LVCMOS33 } [get_ports { iMode[4]}]
set_property -dict { PACKAGE_PIN A18    IOSTANDARD LVCMOS33 } [get_ports { iMode[3]}]
set_property -dict { PACKAGE_PIN AB5    IOSTANDARD LVCMOS33 } [get_ports { iMode[2]}]
set_property -dict { PACKAGE_PIN AB13   IOSTANDARD LVCMOS33 } [get_ports { iMode[1]}]
set_property -dict { PACKAGE_PIN J21    IOSTANDARD LVCMOS33 } [get_ports { iMode[0]}]

set_property -dict { PACKAGE_PIN Y2     IOSTANDARD LVCMOS33 } [get_ports { enable[8]}]
set_property -dict { PACKAGE_PIN K6     IOSTANDARD LVCMOS33 } [get_ports { enable[7]}]
set_property -dict { PACKAGE_PIN J2     IOSTANDARD LVCMOS33 } [get_ports { enable[6]}]
set_property -dict { PACKAGE_PIN K1     IOSTANDARD LVCMOS33 } [get_ports { enable[5]}]
set_property -dict { PACKAGE_PIN H2     IOSTANDARD LVCMOS33 } [get_ports { enable[4]}]
set_property -dict { PACKAGE_PIN B21    IOSTANDARD LVCMOS33 } [get_ports { enable[3]}]
set_property -dict { PACKAGE_PIN AB1    IOSTANDARD LVCMOS33 } [get_ports { enable[2]}]
set_property -dict { PACKAGE_PIN AA10   IOSTANDARD LVCMOS33 } [get_ports { enable[1]}]
set_property -dict { PACKAGE_PIN M21    IOSTANDARD LVCMOS33 } [get_ports { enable[0]}]


set_property -dict { PACKAGE_PIN V3     IOSTANDARD LVCMOS33 } [get_ports { dacDout[8]}]
set_property -dict { PACKAGE_PIN N4     IOSTANDARD LVCMOS33 } [get_ports { dacDout[7]}]
set_property -dict { PACKAGE_PIN G3     IOSTANDARD LVCMOS33 } [get_ports { dacDout[6]}]
set_property -dict { PACKAGE_PIN K2     IOSTANDARD LVCMOS33 } [get_ports { dacDout[5]}]
set_property -dict { PACKAGE_PIN J1     IOSTANDARD LVCMOS33 } [get_ports { dacDout[4]}]
set_property -dict { PACKAGE_PIN B22    IOSTANDARD LVCMOS33 } [get_ports { dacDout[3]}]
set_property -dict { PACKAGE_PIN AA1    IOSTANDARD LVCMOS33 } [get_ports { dacDout[2]}]
set_property -dict { PACKAGE_PIN AA9    IOSTANDARD LVCMOS33 } [get_ports { dacDout[1]}]
set_property -dict { PACKAGE_PIN N22    IOSTANDARD LVCMOS33 } [get_ports { dacDout[0]}]
