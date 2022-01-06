#!/usr/bin/env bash

cd /tmp/ && \
    git clone --recursive https://github.com/scafacos/scafacos.git --branch dipoles && \
    cd /tmp/scafacos && ./bootstrap && ./configure \
        --enable-shared \
        --enable-portable-binary \
        --with-internal-pfft \
        --with-internal-pnfft \
        --enable-fcs-solvers=direct,pnfft,p2nfft,p3m \
        --disable-fcs-fortran \
        --enable-fcs-dipoles && \
    make -j `nproc` && \
    make install && \
    rm -rf /tmp/scafacos

cd /tmp/ && \
    git clone --single-branch -b 4.1 https://github.com/espressomd/espresso.git && \
    cd /tmp/espresso/ && mkdir build

# This file must be copied in Dockerfile.
cp /srv/jupyterhub/myconfig-espresso.h /tmp/espresso/build/myconfig.h

cd /tmp/espresso/build && \
    CC=/usr/bin/gcc-7     \
    CXX=/usr/bin/g++-7    \
    cmake .. &&           \
    make -j `nproc` &&    \
    make install &&       \
    rm -rf /tmp/espresso/

# Failing!
# OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 make check
