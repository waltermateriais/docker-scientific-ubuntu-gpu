# Jupyterhub Docker GPU

This repository provides a Docker environment consisting of a mixture of Data Science and CFD. The environment aims at serving JupyterHub with access to GPU and also allow OpenFOAM and SU2 from that platform. It is built to be an all-in-one system, with several scientific environments and languages available. To have it working some files need to be created and prepared before running `docker-compose` to create the environment.

1. Create and edit `.env` to match the values you expect:
    - PORT_JUPYTERHUB_URI: port to access/expose the hub locally/over a reverse proxy.
    - PROJECTS_ROOT: mount point of `/home` for physical storage of data.
    - GPU_SHM_SIZE: memory of NVidia GPU to be used.
    - The following snipped illustrates a possible content of this file:
    ```bash
    PORT_JUPYTERHUB_URI=8000
    PROJECTS_ROOT=$HOME
    GPU_SHM_SIZE=4gb
    ```

1. Under `config` add the following files:
    - jupyterhub_config.py: configuration file as described [here](https://jupyterhub.readthedocs.io/en/stable/reference/config-reference.html). For version 1.5.0 of JupyterHub, the following snippet would create a PAM authentication system (the simplest one) with a single user called `user`.
    ```python
    c.JupyterHub.bind_url = 'http://0.0.0.0:8000/'
    c.Authenticator.admin_users = {'user'}
    c.Authenticator.allowed_users = {'user'}
    c.LocalAuthenticator.create_system_users = True
    ```
    - make_users.sh: script for adding users, setting passwords and rights. Notice that `jupyterhub_config.py` will not really create the users. This has to be done through the script `make_users.sh`. For creating a single `user` with password `SecretPass*1234` the following content could be added to this script:
    ```bash
    groupadd jupyterusers
    useradd -m -s /bin/bash -G jupyterusers user
    echo 'user:SecretPass*1234' | chpasswd
    ```
    - requirements.txt: typical `pip` file with Python packages to install.
    - rpkgs.r: an R-script managing the installation of required R packages.

1. After filling all the files run `docker-compose up --build` or `docker-compose up -d`, as required.

1. Neither `OpenFOAM` or `SU2` are placed by default on the path of newly added users. To have these software available one can add the following lines to their `.bashrc` or simply source them when required:

```bash
source /opt/SU2/bashrc
source /usr/lib/openfoam/openfoam2106/etc/bashrc
```

If deployment with external access is required, a sample Nginx configuration file is provided [here](config/jupyterhub.conf). You need to set your external domain and port number on this file before placing it under `/etc/nginx/conf.d` and running `systemctl reload nginx`. Notice that SSL is not configured and you will need `certbot` to protect your connection.
