
# Python 3 support
source /afs/slac.stanford.edu/g/reseng/python/3.6.1/settings.csh
#source /afs/slac.stanford.edu/g/reseng/boost/1.62.0_p3/settings.csh
source /afs/slac.stanford.edu/g/reseng/boost/1.64.0/settings.csh

# Python 2 support
#source /afs/slac.stanford.edu/g/reseng/python/2.7.13/settings.csh
#source /afs/slac.stanford.edu/g/reseng/boost/1.62.0_p2/settings.csh

source /afs/slac.stanford.edu/g/reseng/zeromq/4.2.0/settings.csh
source /afs/slac.stanford.edu/g/reseng/epics/base-R3-16-0/settings.csh

# Package directories
setenv HPS_DIR    ${PWD}
setenv SURF_DIR   ${PWD}/../firmware/submodules/surf/
setenv ROGUE_DIR  ${PWD}/rogue
setenv RCE_DIR    ${PWD}/../firmware/submodules/rce-gen3-fw-lib/
setenv AXIPCIE_DIR ${PWD}/../firmware/submodules/axi-pcie-core/

# Setup python path
setenv PYTHONPATH ${PWD}/python:${SURF_DIR}/python:${ROGUE_DIR}/python:${RCE_DIR}/python:${AXIPCIE_DIR}/python:${PYTHONPATH}

# Setup library path
setenv LD_LIBRARY_PATH ${ROGUE_DIR}/lib::${LD_LIBRARY_PATH}


# Boot thread library names differ from system to system, not all have -mt
setenv BOOST_THREAD -lboost_thread-mt

#alias python python3.6
