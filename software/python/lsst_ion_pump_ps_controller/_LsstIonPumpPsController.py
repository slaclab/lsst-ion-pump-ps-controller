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
        pyrogue.streamConnectBiDir(srp, udp)

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
                memBase=srp,
                name=f'FrontEndBoard[{i}]',
                offset=0x00040000 + (0x1000 * i),
            ))

        self.start(pollEn=False)

class FrontEndBoard(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
 
        for i in range(3):
            self.add(pr.RemoteVariable(
               name=f'DAC_RAW[{i}]',
                offset= 0x0100 + (i*4),
                mode='WO'))

            self.add(pr.LinkVariable(
                name=f'DAC_V[{i}]',
                variable=self.DAC_RAW[i],
                linkedGet = lambda raw=self.DAC_RAW[i]: raw.value() * 5.0,
                linkedSet = lambda value, raw=self.DAC_RAW[i]: raw.set(int(value / 5.0)),
                disp='{:1.3f}',
                units = 'V'))

                 
