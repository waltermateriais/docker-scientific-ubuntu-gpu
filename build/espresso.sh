#!/usr/bin/env bash

cd /opt/ && \
    git clone --recursive https://github.com/scafacos/scafacos.git --branch dipoles && \
    cd /opt/scafacos && ./bootstrap && ./configure \
        --enable-shared \
        --enable-portable-binary \
        --with-internal-pfft \
        --with-internal-pnfft \
        --enable-fcs-solvers=direct,pnfft,p2nfft,p3m \
        --disable-fcs-fortran \
        --enable-fcs-dipoles && \
    make -j `nproc` && \
    make install

cd /opt/ && \
    git clone --single-branch -b 4.1 https://github.com/espressomd/espresso.git && \
    cd /opt/espresso/ && mkdir build

# This file must be copied in Dockerfile.
cp /srv/jupyterhub/myconfig-espresso.h /opt/espresso/build/myconfig.h

cd /opt/espresso/build && \
    CC=/usr/bin/gcc-6     \
    CXX=/usr/bin/g++-6    \
    cmake .. &&           \
    make -j `nproc` &&    \
    make install

# Failing!
# OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 make check
