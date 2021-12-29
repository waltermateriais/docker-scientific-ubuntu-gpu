#!/usr/bin/env bash

# This seems abandoned... not building for now.
# cd /opt && git clone --recursive git://github.com/scafacos/scafacos.git && \
# cd scafacos && ./bootstrap && ./configure && make -j 4 && make check && \
# make install

pip install pint

cd /opt && \
    git clone --single-branch -b 4.1 https://github.com/espressomd/espresso.git && \
    mkdir build

# This file must be copied in Dockerfile.
mv /srv/jupyterhub/myconfig-espresso.h /opt/espressomd/build/myconfig.h

cd /opt/espressomd/build && \
    CC=/usr/bin/gcc-7 CXX=/usr/bin/g++-7 cmake .. && \
    make && make install

OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 make check
