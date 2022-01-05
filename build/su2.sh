#!/usr/bin/env sh

# NOTE: use sh, not bash, which leads to git-submodule bugs.

alias python='python3'

apt install -y re2c

cd /opt/ && git clone --recursive https://github.com/su2code/SU2.git

echo "\
export SU2_HOME=/opt/SU2\n\
export SU2_RUN=/opt/SU2/bin\n\
export PATH=/opt/SU2/bin:\$PATH\n\
export PYTHONPATH=/opt/SU2/bin:\$PYTHONPATH\n\
export LD_LIBRARY_PATH=/opt/SU2/lib:\$LD_LIBRARY_PATH\n\
export MPP_DATA_DIRECTORY=/opt/SU2/subprojects/Mutationpp/data\n\
export LD_LIBRARY_PATH=/opt/SU2/build/subprojects/Mutationpp:\$LD_LIBRARY_PATH
" > /opt/SU2/bashrc
 
# Use a ., not source, for sh compatibility.
. /opt/SU2/bashrc

# CPPFLAGS=$(/usr/local/bin/python3-config --cflags) \
# LLFLAGS=$(/usr/local/bin/python3-config --ldflags) \
cd /opt/SU2 && \
CXXFLAGS='-march=native -mtune=native -funroll-loops' \
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
    --optimization=2

cd /opt/SU2 && ./ninja -C build install

# EOF
