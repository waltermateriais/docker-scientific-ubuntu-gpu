#!/usr/bin/env bash

git clone https://github.com/Cantera/cantera.git

cd cantera && git checkout v2.5.1 && \
  scons build \
    CXX=g++ \
    cxx_flags='-std=c++11' \
    CC=gcc \
    cc_flags='' \
    libdirname=lib \
    prefix=/opt/cantera/ \
    python_package=full \
    python_cmd=`which python3` \
    matlab_toolbox='n' \
    matlab_path='' \
    f90_interface='y' \
    FORTRAN=/usr/bin/gfortran \
    FORTRANFLAGS='-O3' \
    coverage='no' \
    doxygen_docs='no' \
    sphinx_docs='no' \
    sphinx_cmd='sphinx-build' \
    sphinx_options='-W --keep-going' \
    system_eigen='n' \
    system_fmt='n' \
    system_yamlcpp='n' \
    system_sundials='n' \
    sundials_include='' \
    sundials_libdir='' \
    blas_lapack_libs='openblas,lapacke' \
    blas_lapack_dir='/lib/x86_64-linux-gnu/' \
    lapack_names='lower' \
    lapack_ftn_trailing_underscore='yes' \
    lapack_ftn_string_len_at_end='yes' \
    googletest='submodule' \
    env_vars='all' \
    thread_flags='-pthread' \
    optimize='yes' \
    optimize_flags='-O3 -Wno-inline' \
    no_optimize_flags='-O0' \
    debug='no' \
    debug_flags='-g' \
    no_debug_flags='' \
    debug_linker_flags='' \
    no_debug_linker_flags='' \
    warning_flags='-Wall' \
    extra_inc_dirs='' \
    extra_lib_dirs='' \
    boost_inc_dir='/usr/include' \
    stage_dir='' \
    VERBOSE='yes' \
    gtest_flags='' \
    renamed_shared_libraries='yes' \
    versioned_shared_library='yes' \
    use_rpath_linkage='yes' \
    layout='standard' \
    fast_fail_tests='no' && \
  scons install && \
  cd .. && rm -rf cantera

# EOF