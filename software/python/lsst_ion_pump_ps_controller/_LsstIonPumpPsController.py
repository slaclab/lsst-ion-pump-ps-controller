import pyrogue as pr
import pyrogue.protocols
import rogue.protocols.srp

import surf.axi
import surf.devices.micron

class LsstIonPumpCtrlRoot(pr.Root):
    def __init__(self, name='LsstIonPumpCtrlRoot', **kwargs):
        super().__init__(description="LSST ION PUMP", name=name, **kwargs)

        # Open UDP socket with RSSI attached
        #udp = pyrogue.protocols.UdpRssiPack(host='192.168.1.10', port=8192, size=1400)
        udp = rogue.protocols.udp.Client('192.168.1.10', 8192, 1400)
        # Create SRP
        srp = rogue.protocols.srp.SrpV3()

        # Attach SRP to UDP - TDEST 0
        pyrogue.streamConnectBiDir(srp, udp.application(0))

        self.add(surf.axi.AxiVersion(
            memBase=srp,
            offset=0x0,
        ))

        self.add(surf.devices.micron.AxiMicronN25Q(
            memBase=srp,
            offset=0x00020000
        ))

        for i in range(5):
            self.add(FrontEndBoard(
                name='FrontEndBoard[{i}]',
                offset=0x00040000 + (0x1000 * i),
            ))

class FrontEndBoard(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(self, **kwargs)

        self.add(Regs(
            offset=0x0000,
        ))

        self.add(pr.RemoteVariable(
            name='HwEnable',
            offset=0x0,
            bitOffset=0,
            mode='RW',
            base=pr.Bool,
        ))

        self.add(pr.RemoteVariable(
            name='IMode',
            offset=0x0,
            bitOffset=1,
            mode='RO',
            base=pr.Bool,
        ))
        self.add(pr.RemoteVariable(
            name='VMode',
            offset=0x0,
            bitOffset=2,
            mode='RO',
            base=pr.Bool,            
        ))
        self.add(pr.RemoteVariable(
            name='PMode',
            offset=0x0,
            bitOffset=3,
            mode='RO',
            base=pr.Bool,            
        ))

        for i in range(3):
            self.add(pr.RemoteVariable(
                name='DAC[{i}]',
                offset= 0x0100 + (i*4)
            ))

        for i in range(3):
            self.add(pr.RemoteVariable(
                name='ADC[{i}]',
                offset= 0x0200 + (i*4)
            ))
            
                
