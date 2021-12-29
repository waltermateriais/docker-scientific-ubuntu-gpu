##############################################################################
# GPU ENABLED JUPYTERHUB AND MASTER SCIENTIFIC ENVIRONMENT
##############################################################################

FROM nvidia/cuda:11.4.2-cudnn8-runtime-ubuntu20.04
LABEL authors="Walter Dal'Maz Silva <walter.dalmazsilva@gmail.com>"

ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/

##############################################################################
# GENERAL DEVEL ENVIRONMENT
##############################################################################

COPY build/apt.sh /srv/jupyterhub/
RUN chmod u+x apt.sh && ./apt.sh

RUN curl -sSL https://get.haskellstack.org/ | sh
RUN python3 -m pip install --upgrade setuptools pip wheel

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt install -y nodejs

ENV DEBIAN_FRONTEND noninteractive
RUN apt install -y keyboard-configuration

RUN echo "deb https://build.openmodelica.org/apt `lsb_release -cs` stable" | \
    tee /etc/apt/sources.list.d/openmodelica.list && \
    wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | apt-key add -  && \
    apt-key fingerprint && apt update && apt install -y openmodelica

RUN add-apt-repository ppa:fenics-packages/fenics && \
    apt update && apt -y install fenics

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
# SIMULATION
##############################################################################

RUN curl -s https://dl.openfoam.com/add-debian-repo.sh | bash && \
    wget -q -O - https://dl.openfoam.com/add-debian-repo.sh | bash && \
    apt install -y openfoam2106-default

RUN cd /opt/ && git clone https://github.com/su2code/SU2.git

COPY build/su2.sh /srv/jupyterhub/
RUN chmod u+x su2.sh && ./su2.sh

COPY build/cantera.sh /srv/jupyterhub/
RUN chmod u+x cantera.sh && ./cantera.sh

# TODO OpenCalphad: automate Makefile edition.
COPY build/opencalphad.sh /srv/jupyterhub/
RUN cd /opt/ && git clone https://github.com/sundmanbo/opencalphad.git

COPY build/espresso.sh /srv/jupyterhub/
COPY config/myconfig-espresso.h /srv/jupyterhub/
RUN chmod +x /srv/jupyterhub/espresso.sh && ./espresso.sh

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