#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : 
#-----------------------------------------------------------------------------
# File       : TopLevel.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# 
#-----------------------------------------------------------------------------
# This file is part of the rogue_example software. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the rogue_example software, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr
import LsstPwrCtrlCore as base
  
class Fpga(pr.Device):
    def __init__(self, 
                 name        = "Fpga",
                 description = "Device Memory Mapping",
                 **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        coreStride = 0x40000 
        appStride  = 0x1000 
        
        # Add Core device
        self.add(base.Core())            
        
        # Add User devices
        self.add(CtrlReg(
            name    = 'Registers',
            offset  = (1*coreStride)+ (appStride * 0),
            expand  = False,
        ))

        for i in range(9):
            self.add(Channel(
                name   = ('Channel[%d]' % i),
                offset = (1*coreStride) + (appStride * (1+i)),
                expand = False,
            ))        
        
class Channel(pr.Device):
    def __init__(self, 
                 name        = "Channel",
                 description = "Container for Channel",
                 **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name    = 'CurrentLimit',
            offset  = 0x0,
            mode    = 'WO',
        ))
        self.add(pr.RemoteVariable(
            name    = 'VoltageLimit',
            offset  = 0x4,
            mode    = 'WO',
        ))
        self.add(pr.RemoteVariable(
            name    = 'PowerLimit',
            offset  = 0x8,
            mode    = 'WO',
        ))
        self.add(pr.RemoteVariable(
            name    = 'Current',
            offset  = 0x200,
            mode    = 'RO',
        ))
        self.add(pr.RemoteVariable(
            name    = 'Voltage',
            offset  = 0x204,
            mode    = 'RO',
        ))
        self.add(pr.RemoteVariable(
            name    = 'Power',
            offset  = 0x208,
            mode    = 'RO',
        ))

class CtrlReg(pr.Device):
    def __init__(self, 
                 name        = "CtrlReg",
                 description = "Container for CtrlReg",
                 **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        self.add(pr.RemoteVariable(
            name    = 'ChannelEnable',
            offset  = 0x0,
            mode    = 'RW',
        ))
        self.add(pr.RemoteVariable(
            name    = 'IModeStatus',
            offset  = 0x04,
            mode    = 'RO',
        ))
        self.add(pr.RemoteVariable(
            name    = 'VModeStatus',
            offset  = 0x08,
            mode    = 'RO',
        ))
        self.add(pr.RemoteVariable(
            name    = 'PModeStatus',
            offset  = 0x0C,
            mode    = 'RO',
        ))
