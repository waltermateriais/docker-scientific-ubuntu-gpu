##############################################################################
# GPU ENABLED JUPYTERHUB AND MASTER SCIENTIFIC ENVIRONMENT
#
# References
# ==========
# https://hub.docker.com/r/nvidia/cuda/tags
# https://hub.docker.com/r/jupyterhub/jupyterhub
# https://pypi.org/project/jupyterhub/2.0.0/
# https://github.com/jupyterhub/jupyterhub/blob/main/Dockerfile
# https://doc.sagemath.org/html/en/installation/conda.html
# https://github.com/gibiansky/IHaskell
# https://irkernel.github.io/installation/
# https://stackoverflow.com/questions/47615751
# https://askubuntu.com/questions/876240
# https://askubuntu.com/questions/313089
#
# The following languages/dialects are supported in Notebooks:
# - Python
# - Lua
# - Octave
# - SageMath
# - R
#
# The following languages are installed, users must add their kernels:
# - Julia
# - Haskell
# 
# For general CLI development only there is also:
# - C/C++
# - Fortran
# - Rust
# - NodeJS
#
##############################################################################

FROM nvidia/cuda:11.4.2-cudnn8-runtime-ubuntu20.04
LABEL authors="Walter Dal'Maz Silva <walter.dalmazsilva@gmail.com>"

ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

##############################################################################
# GENERAL DEVEL ENVIRONMENT
##############################################################################

RUN apt update && \
    apt upgrade -y && \
    apt install -yq --no-install-recommends \
    build-essential \
    ca-certificates \
    locales \
    dirmngr \
    gnupg \
    apt-transport-https \
    software-properties-common

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'

RUN apt update && \
    apt upgrade -y && \
    apt install -yq --no-install-recommends \
    python3-dev \
    python3-pip \
    python3-pycurl \
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
    ninja-build \
    octave \
    r-base \
    julia \
    lua5.3 \
    swig \
    python3-mpi4py \
    haskell-platform \
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
    libqt5widgets5

RUN curl -sSL https://get.haskellstack.org/ | sh
RUN python3 -m pip install --upgrade setuptools pip wheel

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt install -y nodejs
RUN apt clean

##############################################################################
# INSTALL JUPYTERHUB
##############################################################################

RUN apt remove -y python3-terminado
RUN npm install -g configurable-http-proxy
RUN pip install \
    'jupyterhub<2.0.0' \
    ruamel_yaml \
    jupyter \
    notebook \
    jupyterlab \
    voila

# Because of removal of system's python3-terminado.
RUN apt install -y sagemath

##############################################################################
# CFD
##############################################################################

RUN curl -s https://dl.openfoam.com/add-debian-repo.sh | bash && \
    wget -q -O - https://dl.openfoam.com/add-debian-repo.sh | bash && \
    apt install -y openfoam2106-default

RUN cd /opt/ && git clone https://github.com/su2code/SU2.git

RUN echo "\
    export SU2_HOME=/opt/SU2\
    export SU2_RUN=/opt/SU2/bin\
    export PATH=/opt/SU2/bin:\$PATH\
    export PYTHONPATH=/opt/SU2/bin:\$PYTHONPATH\
    export LD_LIBRARY_PATH=/opt/SU2/lib:\$LD_LIBRARY_PATH\
    " > /opt/SU2/bashrc && . /opt/SU2/bashrc && \
    cd /opt/SU2 && CXXFLAGS='-march=native -mtune=native -funroll-loops' \
    ./meson.py build \
    -Dwith-mpi=enabled \
    -Dwith-omp=true \
    -Denable-tecio=true \
    -Denable-cgns=true \
    -Denable-autodiff=true \
    -Denable-directdiff=true \
    -Denable-pywrapper=true \
    -Denable-mkl=false \
    -Dmkl_root=/opt/intel/mkl \
    -Denable-openblas=true \
    -Dblas-name=openblas \
    -Denable-pastix=false \
    -Dpastix_root=externals/pastix/ \
    -Dscotch_root=externals/scotch/ \
    -Dcustom-mpi=false \
    -Denable-tests=true \
    -Denable-mixedprec=true \
    -Dextra-deps=lapack \
    -Denable-mpp=true \
    -Dopdi-backend=auto \
    -Dcodi-tape=JacobianLinear \
    -Dopdi-shared-read-opt=true \
    -Dlibrom_root='' \
    -Denable-librom=false \
    --prefix=/opt/SU2 \
    --optimization=2 && \
    cd /opt/SU2 && ./ninja -C build install

##############################################################################
# JUPYTER WORKING CONDITIONS
##############################################################################

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/
COPY config/jupyterhub_config.py /srv/jupyterhub/

COPY config/requirements.txt /srv/jupyterhub/
RUN pip install -r requirements.txt
RUN python3 -m lua_kernel.install

COPY config/rpkgs.r /srv/jupyterhub/
# RUN Rscript /srv/jupyterhub/rpkgs.r
# RUN R -e 'IRkernel::installspec(user = FALSE)'

COPY config/make_users.sh /srv/jupyterhub/
RUN chmod +x /srv/jupyterhub/make_users.sh

RUN groupadd jupyterusers
EXPOSE 8000
ENTRYPOINT []

##############################################################################
# EOF
##############################################################################