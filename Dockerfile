##############################################################################
# GPU ENABLED JUPYTERHUB AND MASTER SCIENTIFIC ENVIRONMENT
##############################################################################

FROM ubuntu:18.04
LABEL authors="Walter Dal'Maz Silva <walter.dalmazsilva@gmail.com>"

# Define environment to avoid later prompts.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Add base service directory/group.
RUN groupadd jupyterusers
RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/

# Ensure base system is up-to-date.
RUN apt update && apt upgrade -y

# Install Linux basics for build/install.
RUN apt install -y \
    build-essential \
    ca-certificates \
    locales \
    dirmngr \
    gnupg \
    apt-transport-https \
    software-properties-common \
    keyboard-configuration

##############################################################################
# GENERAL CUDA ENVIRONMENT
##############################################################################

# Note: if migrating to 20.04 add nvidia-cuda-toolkit-gcc
RUN apt install -y \
    libnvidia-compute-460 \
    nvidia-utils-460 \
    nvidia-cuda-dev \
    nvidia-cuda-gdb \
    nvidia-cuda-toolkit

COPY libs/libcudnn8*.deb  /srv/jupyterhub/

RUN apt install -y dpkg                                     && \
    dpkg -i libcudnn8_8.1.1.33-1+cuda11.2_amd64.deb         && \
    dpkg -i libcudnn8-dev_8.1.1.33-1+cuda11.2_amd64.deb     && \
    dpkg -i libcudnn8-samples_8.1.1.33-1+cuda11.2_amd64.deb

##############################################################################
# COMMON UTILITIES AND LIBRARIES
##############################################################################

# Extra required to build R.
RUN add-apt-repository ppa:openjdk-r/ppa

# General Linux utilities.
RUN apt update && apt install -y \
    apt-utils \
    autoconf \
    automake \
    bison \
    ccache \
    cgns-convert \
    clang-9 \
    clang-format-9 \
    clang-tidy-9 \
    cmake \
    cmake-curses-gui \
    curl \
    doxygen \
    fftw3-dev \
    g++ \
    g++-7 \
    gcc \
    gcc-7 \
    gdb \
    gfortran \
    git \
    graphviz \
    haskell-platform \
    htop \
    jq \
    lcov \
    libblas-dev \
    libboost-all-dev \
    libbz2-dev \
    libcairo2-dev \
    libcgns-dev \
    libcurl4-openssl-dev \
    libffi-dev \
    libfftw3-dev \
    libgdbm-dev \
    libgl1-mesa-glx \
    libgl1-mesa-glx \
    libgsl-dev \
    libhdf5-dev \
    libhdf5-openmpi-dev \
    liblapack-dev \
    liblapacke-dev \
    liblzma-dev \
    libmagic-dev \
    libncurses5-dev \
    libnss3-dev \
    libopenblas-dev \
    libopenmpi-dev \
    libpango1.0-dev \
    libpcre2-dev \
    libpng-dev \
    libqt5widgets5 \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libthrust-dev \
    libtiff5-dev \
    libtinfo-dev \
    libtool \
    libxext6 \
    libxml2-dev \
    libxrender1 \
    libxt6 \
    libzmq3-dev \
    lua5.3 \
    lzma \
    lzma-dev \
    make \
    mpich \
    ninja-build \
    octave \
    openjdk-11-jre \
    openmpi-bin \
    openmpi-common \
    openssh-client \
    petsc-dev \
    pkg-config \
    rsync \
    sagemath \
    ssh \
    swig \
    tar \
    texlive-full \
    tk8.6-dev \
    uuid-dev \
    vim \
    wget \
    xvfb \
    zlib1g-dev

# Install Haskell Stack.
RUN curl -sSL https://get.haskellstack.org/ | sh

# Install recent NodeJS.
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt install -y nodejs

# Install Modelica.
RUN echo "deb https://build.openmodelica.org/apt `lsb_release -cs` stable" | \
    tee /etc/apt/sources.list.d/openmodelica.list && \
    wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | apt-key add - && \
    apt-key fingerprint && apt update && apt install -y openmodelica

##############################################################################
# OPENFOAM
##############################################################################

RUN curl -s https://dl.openfoam.com/add-debian-repo.sh | bash && \
    wget -q -O - https://dl.openfoam.com/add-debian-repo.sh | bash && \
    apt install -y openfoam2112-default

RUN sh -c "wget -O - https://dl.openfoam.org/gpg.key | apt-key add -" && \
    add-apt-repository http://dl.openfoam.org/ubuntu && \
    apt update && apt install -y openfoam9

##############################################################################
# COMPILE LANGUAGES
##############################################################################

# Build/install Python.
RUN cd /opt/ && \
    git clone --recursive https://github.com/python/cpython.git && \
    cd /opt/cpython && git checkout tags/v3.9.9 && ./configure \
        --enable-optimizations --with-lto --enable-shared && \
    make -j 4 && make test && make install && ldconfig

# Build/install R.
RUN cd /opt/ && \
    wget https://pbil.univ-lyon1.fr/CRAN/src/base/R-4/R-4.1.2.tar.gz && \
    tar xzf R-4.1.2.tar.gz && rm -rf R-4.1.2.tar.gz && \
    cd R-4.1.2 && mkdir build && cd build && \
    ../configure \
        --enable-R-shlib \
        --enable-R-static-lib \
        --enable-lto \
        --enable-long-double \
        --with-lapack \
        --with-readline \
        --with-pcre2 \
    && make all && make install

# Build/install Julia.
RUN cd /opt/ && \
    git clone https://github.com/JuliaLang/julia.git && \
    cd julia && git checkout v1.6.1 && make -j 4 && make install

##############################################################################
# INSTALL LANGUAGE FEATURES/MORE LANGUAGES
##############################################################################

# Up-to-date python.
RUN LD_LIBRARY_PATH=/usr/local/lib/ \
    python3 -m pip install --upgrade setuptools pip wheel

# Create python environment.
COPY config/requirements.txt .
RUN LD_LIBRARY_PATH=/usr/local/lib/ \
    pip3 install -r requirements.txt && \
    LD_LIBRARY_PATH=/usr/local/lib/ \
    python3 -m lua_kernel.install

COPY config/rpkgs.r .
RUN Rscript rpkgs.r && \
    R -e 'IRkernel::installspec(user = FALSE)'

##############################################################################
# INSTALL JUPYTERHUB
##############################################################################

RUN npm install -g configurable-http-proxy && \
    LD_LIBRARY_PATH=/usr/local/lib/ pip3 install \
    'jupyterhub<2.0.0' \
    ruamel_yaml \
    jupyter \
    notebook \
    jupyterlab \
    voila

##############################################################################
# SIMULATION
##############################################################################

# Install nvtop for monitoring GPU.
RUN cd /opt/ && \
    git clone https://github.com/Syllo/nvtop.git && \
    mkdir -p /opt/nvtop/build && cd /opt/nvtop/build && \
    cmake .. && make && make install

# Install FEniCS.
# XXX: https://fenics.readthedocs.io/en/latest/installation.html
RUN add-apt-repository ppa:fenics-packages/fenics && \
    apt update && apt -y install fenics

# Install lammps
# XXX: only for now, later compile it.
RUN add-apt-repository ppa:gladky-anton/lammps && \
    add-apt-repository ppa:openkim/latest && \
    apt update && apt install -y \
        lammps-stable \
        lammps-stable-data \
        openkim-models

# Install ESPResSo MD.
COPY build/espresso.sh .
COPY config/myconfig-espresso.h .
RUN chmod +x /srv/jupyterhub/espresso.sh && \
    LD_LIBRARY_PATH=/usr/local/lib/ ./espresso.sh

# Install SU2.
COPY build/su2.sh .
RUN chmod u+x su2.sh && \
    LD_LIBRARY_PATH=/usr/local/lib/ ./su2.sh

# TODO OpenCalphad: automate Makefile edition.
COPY build/opencalphad.sh .
RUN cd /opt/ && git clone https://github.com/sundmanbo/opencalphad.git

# Install Cantera.
COPY build/cantera.sh .
RUN chmod u+x cantera.sh && \
    LD_LIBRARY_PATH=/usr/local/lib/ ./cantera.sh

##############################################################################
# PATCHES
##############################################################################

RUN ln -s /opt/cantera/lib/python3.9/site-packages/cantera \
    /usr/local/lib/python3.9/site-packages/ && \
    ln -s /opt/cantera/lib/python3.9/site-packages/Cantera-2.5.1-py3.9.egg-info \
    /usr/local/lib/python3.9/site-packages/ && \
    sed -i  "s|which python|which python3|g" /opt/cantera/bin/setup_cantera

##############################################################################
# JUPYTER WORKING CONDITIONS
##############################################################################

# Jupyter extensions.
RUN pip3 install --upgrade jupyterlab jupyterlab-git
RUN jupyter labextension install jupyterlab-plotly
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget
RUN jupyter labextension install @techrah/text-shortcuts
RUN jupyter labextension install jupyterlab-spreadsheet
RUN pip3 install \
    jupyterlab-execute-time \
    jupyterlab-drawio \
    jupyterlab_theme_solarized_dark \
    jupyter_bokeh \
    ipympl \
    lckr-jupyterlab-variableinspector

COPY config/jupyterhub_config.py .

##############################################################################
# TESTING
##############################################################################

# Julia/espresso cannot be tested with root user.
# RUN useradd -m -s /bin/bash -G jupyterusers nonroot

# RUN chown -R nonroot:nonroot /opt/espresso
# USER nonroot
# RUN cd /opt/espresso/build && make check
# USER root
# RUN chown -R root:root /opt/espresso

# RUN chown -R nonroot:nonroot /opt/julia
# USER nonroot
# RUN cd /opt/julia && make testall
# USER root
# RUN chown -R root:root /opt/julia

##############################################################################
# ENTRYPOINT
##############################################################################

COPY config/make_users.sh .
RUN chmod +x make_users.sh

EXPOSE 8000
EXPOSE 8333

RUN apt clean

ENTRYPOINT []

##############################################################################
# EOF
##############################################################################



