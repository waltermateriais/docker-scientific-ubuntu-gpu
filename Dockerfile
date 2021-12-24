##############################################################################
# GPU ENABLED JUPYTERHUB AND MASTER SCIENTIFIC ENVIRONMENT
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
    libqt5widgets5 \
    cgns-convert \
    libcgns-dev

RUN curl -sSL https://get.haskellstack.org/ | sh
RUN python3 -m pip install --upgrade setuptools pip wheel

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt install -y nodejs

ENV DEBIAN_FRONTEND noninteractive
RUN apt install -y keyboard-configuration

RUN echo "deb https://build.openmodelica.org/apt `lsb_release -cs` stable" | tee /etc/apt/sources.list.d/openmodelica.list && \
    wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | apt-key add -  && \
    apt-key fingerprint && apt update && apt install -y openmodelica

RUN add-apt-repository ppa:fenics-packages/fenics && \
    apt update && apt -y install fenics

RUN apt clean

##############################################################################
# INSTALL JUPYTERHUB
##############################################################################

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/

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

COPY build/su2.sh /srv/jupyterhub/
RUN chmod u+x su2.sh && ./su2.sh

##############################################################################
# CANTERA
##############################################################################

COPY build/cantera.sh /srv/jupyterhub/
RUN chmod u+x cantera.sh && ./cantera.sh

##############################################################################
# JUPYTER WORKING CONDITIONS
##############################################################################

COPY config/jupyterhub_config.py /srv/jupyterhub/

COPY config/rpkgs.r /srv/jupyterhub/
RUN Rscript /srv/jupyterhub/rpkgs.r
RUN R -e 'IRkernel::installspec(user = FALSE)'

COPY config/requirements.txt /srv/jupyterhub/
RUN pip install -r requirements.txt
RUN python3 -m lua_kernel.install
RUN pip install mpi4py

COPY config/make_users.sh /srv/jupyterhub/
RUN chmod +x /srv/jupyterhub/make_users.sh

RUN groupadd jupyterusers
EXPOSE 8000

RUN pip install --upgrade jupyterlab jupyterlab-git
RUN jupyter labextension install jupyterlab-plotly
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget
RUN jupyter labextension install @techrah/text-shortcuts
RUN jupyter labextension install jupyterlab-spreadsheet

RUN pip install \
    jupyterlab-execute-time \
    jupyterlab-drawio \
    jupyterlab_theme_solarized_dark \
    jupyter_bokeh \
    ipympl \
    lckr-jupyterlab-variableinspector

##############################################################################
# PATCHES
##############################################################################

RUN ln -s /opt/cantera/lib/python3.8/site-packages/cantera \
    /usr/local/lib/python3.8/dist-packages/ && \
    ln -s /opt/cantera/lib/python3.8/site-packages/Cantera-2.5.1-py3.8.egg-info \
    /usr/local/lib/python3.8/dist-packages/ && \
    sed -i  "s|which python|which python3|g" /opt/cantera/bin/setup_cantera

##############################################################################
# ENTRYPOINT
##############################################################################

ENTRYPOINT []

##############################################################################
# EOF
##############################################################################