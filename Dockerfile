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

# RUN echo "\
#     export SU2_HOME=/opt/SU2\n\
#     export SU2_RUN=/opt/SU2/bin\n\
#     export PATH=/opt/SU2/bin:\$PATH\n\
#     export PYTHONPATH=/opt/SU2/bin:\$PYTHONPATH\n\
#     export LD_LIBRARY_PATH=/opt/SU2/lib:\$LD_LIBRARY_PATH\n\
#     " > /opt/SU2/bashrc && . /opt/SU2/bashrc && \
#     cd /opt/SU2 && CXXFLAGS='-march=native -mtune=native -funroll-loops' \
#     ./meson.py build \
#     -Dwith-mpi=enabled \
#     -Dwith-omp=true \
#     -Denable-tecio=true \
#     -Denable-cgns=true \
#     -Denable-autodiff=true \
#     -Denable-directdiff=true \
#     -Denable-pywrapper=true \
#     -Denable-mkl=false \
#     -Dmkl_root=/opt/intel/mkl \
#     -Denable-openblas=true \
#     -Dblas-name=openblas \
#     -Denable-pastix=false \
#     -Dpastix_root=externals/pastix/ \
#     -Dscotch_root=externals/scotch/ \
#     -Dcustom-mpi=false \
#     -Denable-tests=true \
#     -Denable-mixedprec=true \
#     -Dextra-deps=lapack \
#     -Denable-mpp=true \
#     -Dopdi-backend=auto \
#     -Dcodi-tape=JacobianLinear \
#     -Dopdi-shared-read-opt=true \
#     -Dlibrom_root='' \
#     -Denable-librom=false \
#     --prefix=/opt/SU2 \
#     --optimization=2 && \
#     cd /opt/SU2 && ./ninja -C build install

##############################################################################
# CANTERA
##############################################################################

COPY build/cantera.sh /srv/jupyterhub/
RUN chmod u+x cantera.sh && ./cantera.sh

# RUN pip install scons
# RUN git clone https://github.com/Cantera/cantera.git && \
#     cd cantera && git checkout v2.5.1 && \
#     scons build \
#         CXX=g++ \
#         cxx_flags='-std=c++11' \
#         CC=gcc \
#         cc_flags='' \
#         libdirname=lib \
#         prefix=/opt/cantera/ \
#         python_package=full \
#         python_cmd=/usr/bin/python3 \
#         matlab_toolbox='n' \
#         matlab_path='' \
#         f90_interface='y' \
#         FORTRAN=/usr/bin/gfortran \
#         FORTRANFLAGS='-O3' \
#         coverage='no' \
#         doxygen_docs='no' \
#         sphinx_docs='no' \
#         sphinx_cmd='sphinx-build' \
#         sphinx_options='-W --keep-going' \
#         system_eigen='n' \
#         system_fmt='n' \
#         system_yamlcpp='n' \
#         system_sundials='n' \
#         sundials_include='' \
#         sundials_libdir='' \
#         blas_lapack_libs='openblas,lapacke' \
#         blas_lapack_dir='/lib/x86_64-linux-gnu/' \
#         lapack_names='lower' \
#         lapack_ftn_trailing_underscore='yes' \
#         lapack_ftn_string_len_at_end='yes' \
#         googletest='submodule' \
#         env_vars='all' \
#         thread_flags='-pthread' \
#         optimize='yes' \
#         optimize_flags='-O3 -Wno-inline' \
#         no_optimize_flags='-O0' \
#         debug='no' \
#         debug_flags='-g' \
#         no_debug_flags='' \
#         debug_linker_flags='' \
#         no_debug_linker_flags='' \
#         warning_flags='-Wall' \
#         extra_inc_dirs='' \
#         extra_lib_dirs='' \
#         boost_inc_dir='/usr/include' \
#         stage_dir='' \
#         VERBOSE='yes' \
#         gtest_flags='' \
#         renamed_shared_libraries='yes' \
#         versioned_shared_library='yes' \
#         use_rpath_linkage='yes' \
#         layout='standard' \
#         fast_fail_tests='no' && \
#     scons install
# RUN rm -rf cantera

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