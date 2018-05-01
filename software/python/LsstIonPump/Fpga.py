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
            base = pr.UInt,
            bitSize = 16,
        ))
        
        self.add(pr.LinkVariable(
            name = 'Current',
            dependencies = [self.CurrentLimit],
            linkedGet = lambda: self.CurrentLimit.value()*16.0 / 65536.0,
            linkedSet = lambda value, write: self.CurrentLimit.set(int(value/16.0*65536.0), write=write),
            disp = '{:1.3f}',
            ))
        
        self.add(pr.RemoteVariable(
            name    = 'VoltageLimit',
            hidden = False,
            offset  = 0x4,
            mode    = 'WO',
            base = pr.UInt,
            bitSize = 16,
        ))
        self.add(pr.LinkVariable(
            name = 'Voltage',
            dependencies = [self.VoltageLimit],
            linkedGet = lambda: self.VoltageLimit.value()*6.0 /65536.0 ,
            linkedSet = lambda value, write: self.VoltageLimit.set(int(value/6.0*65536.0), write=write),
            disp = '{:1.3f}',
            ))
        
        self.add(pr.RemoteVariable(
            name    = 'PowerLimit',
            offset  = 0x8,
            mode    = 'WO',
            base = pr.UInt,
            bitSize = 16,
        ))
        
        self.add(pr.LinkVariable(
            name = 'Power',
            dependencies = [self.PowerLimit],
            linkedGet = lambda: self.PowerLimit.value()*10.0 /65536.0 ,
            linkedSet = lambda value, write: self.PowerLimit.set(int(value/10.0*65536.0), write=write),
            disp = '{:1.3f}',
            ))
        self.add(pr.RemoteVariable(
            name    = 'CurrentRaw',
            offset  = 0x200,
            mode    = 'RO',
            base = pr.UInt,
            bitSize = 24,
        ))
        self.add(pr.LinkVariable(
            name = 'SupplyCurrent',
            mode = 'RO',
            units = 'mA',
            variable = self.CurrentRaw,
            linkedGet = lambda: self.CurrentRaw.value() *  2.0 * 16.0 / 16777215.0,
            disp = '{:1.3f}',
        ))
 
        self.add(pr.RemoteVariable(
            name    = 'VoltageRaw',
            offset  = 0x204,
            mode    = 'RO',
            base = pr.UInt,
            bitSize = 24,
        ))
        
        self.add(pr.LinkVariable(
            name = 'SupplyVoltage',
            mode = 'RO',
            units = 'KV',
            variable = self.VoltageRaw,
            linkedGet = lambda: self.VoltageRaw.value() *  2.0 * 6.0 / 16777215.0,
            disp = '{:1.3f}',
        ))
 
        self.add(pr.RemoteVariable(
            name    = 'PowerRaw',
            offset  = 0x208,
            mode    = 'RO',
            base = pr.UInt,
            bitSize = 24,
        ))

        self.add(pr.LinkVariable(
            name = 'SupplyPower',
            mode = 'RO',
            units = 'W',
            variable = self.PowerRaw,
            linkedGet = lambda: self.PowerRaw.value() *  2.0 * 10.0 / 16777215.0,
            disp = '{:1.3f}',
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
