#!/usr/bin/env bash

# Base install of libraries.
apt update && \
apt upgrade -y && \
apt install -yq --no-install-recommends \
    build-essential \
    ca-certificates \
    locales \
    dirmngr \
    gnupg \
    apt-transport-https \
    software-properties-common

# Add R repository for latest version.
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'

# Add general development.
apt update && apt upgrade -y && \
apt install -yq --no-install-recommends \
    python3-dev \
    python3-pip \
    python3-pycurl \
    python3-mpi4py \
	python3-opengl \
    rsync \
    curl \
    wget \
    tar \
    git \
    nvtop \
    htop \
    vim \
    gcc \
    g++ \
    gfortran \
    gdb \
    clang \
    mpich \
    make \
    cmake \
    cmake-curses-gui \
    ninja-build \
    doxygen \
    octave \
    r-base \
    julia \
    lua5.3 \
    swig \
    haskell-platform \
    texlive-full 

# Cuda development.
apt install -yq --no-install-recommends \
	nvidia-cuda-toolkit \
	nvidia-cuda-dev\
	nvidia-cuda-toolkit-gcc \
    nvidia-cuda-toolkit-gdb \
    gcc-7 \
    g++-7

# Add general libraries.
apt install -yq --no-install-recommends \
    libboost-all-dev \
    libtinfo-dev \
    libzmq3-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libmagic-dev \
    libblas-dev \
    liblapack-dev \
    libopenblas-dev\
    liblapacke-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgl1-mesa-glx \
    xvfb \
    libxt6 \
    libxrender1 \
    libxext6 \
    libgl1-mesa-glx \
    libqt5widgets5 \
	openmpi-common \
	fftw3-dev \
    libgsl-dev \
	libhdf5-dev \
	libhdf5-openmpi-dev \
	libgsl-dev

# Add CGNS.
apt install -yq --no-install-recommends \
    cgns-convert \
    libcgns-dev
