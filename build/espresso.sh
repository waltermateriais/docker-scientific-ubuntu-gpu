#!/usr/bin/env bash

# This seems abandoned... not building for now.
# Apparently not, it is considered *ready* in literature, add it!
# cd /opt && git clone --recursive git://github.com/scafacos/scafacos.git && \
# cd scafacos && ./bootstrap && ./configure && make -j 4 && make check && \
# make install

pip3 install pint

cd /opt/ && \
    git clone --single-branch -b 4.1 https://github.com/espressomd/espresso.git && \
    cd /opt/espresso/ && mkdir build

# This file must be copied in Dockerfile.
cp /srv/jupyterhub/myconfig-espresso.h /opt/espresso/build/myconfig.h

cd /opt/espresso/build && \
    CC=/usr/bin/gcc-6     \
    CXX=/usr/bin/g++-6    \
    cmake .. &&           \
    make && make install

# Failing!
# OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 make check
