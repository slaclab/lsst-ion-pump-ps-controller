import lsst-ion-pump-ps-controller as lippc

import rogue
import PyQt4.QtGui
import PyQt4.QtCore

if __name__ == "__main__":

    rogue.Logging.setFilter('pyrogue.SrpV3', rogue.Logging.Debug)
    
    with lippc.LsstIonPumpCtrlRoot() as root:
        appTop = PyQt4.QtGui.QApplication(sys.argv)
        guiTop = pyrogue.gui.GuiTop(group='Main')
        print('guiTop.addTree')
        guiTop.addTree(root)
        guiTop.resize(1000,1000)
        # Run gui
        print('appTop.exec_()')
        appTop.exec_()
