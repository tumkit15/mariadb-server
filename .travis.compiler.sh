#!/bin/sh
set -v -x
# Clang:
#   mroonga just generates too many warnings with clang and travis stops the job
#   tokudb has fatal warnings

#CMAKE_OPT="${CMAKE_OPT} -DWITH_ASAN=ON"
# With ASAN mtr processes --thread-stack=400K to account for overhead

CMAKE_OPT=""
if [[ "${TRAVIS_OS_NAME}" == 'linux' ]]; then
  if [[ "${CXX}" == 'clang++' ]]; then
    CMAKE_OPT="${CMAKE_OPT} -DWITHOUT_TOKUDB_STORAGE_ENGINE=ON -DWITHOUT_MROONGA_STORAGE_ENGINE=ON"
    case ${GCC_VERSION} in
      5) CXX=clang++-4.0 ;;
      6) CXX=clang++-5.0 ;;
    esac
    export CXX CC=${CXX/++/}
  elif [[ "${CXX}" == 'g++' ]]; then
    export CXX=g++-${GCC_VERSION}
    export CC=gcc-${GCC_VERSION}
  fi
  # Pull newer version of ccache (same libc/zlib as Trusty)
  if [[ ! -f ${HOME}/extras/usr/bin/ccache ]]; then
    wget http://ftp.osuosl.org/pub/ubuntu/pool/main/c/ccache/ccache_3.3.4-1_amd64.deb
    ar vx ccache_3.3.4-1_amd64.deb
    tar -xJvf data.tar.xz -C ${HOME}/extras
  fi
  export PATH="${HOME}/extras/usr/bin:$PATH"
  if [[ ${GCC_VERSION} == 6 && ! -f ${HOME}/extras/usr/lib/libgalera_smm.so ]]; then
         wget http://mirrors.kernel.org/ubuntu/pool/universe/p/percona-xtradb-cluster-galera-2.x/percona-xtradb-cluster-galera-2.x_165-0ubuntu1_amd64.deb
         ar vx percona-xtradb-cluster-galera-2.x_165-0ubuntu1_amd64.deb
         tar -xJvf data.tar.xz -C extras
         export WSREP_PROVIDER=$HOME/extras/usr/lib/libgalera_smm.so
         MYSQL_TEST_SUITES="${MYSQL_TEST_SUITES},wsrep"
  fi
else
  # osx_image based tests
  export PATH="/usr/local/opt/ccache/libexec:$PATH"
  CMAKE_OPT="${CMAKE_OPT} -DOPENSSL_ROOT_DIR=/usr/local/opt/openssl"
  CMAKE_OPT="${CMAKE_OPT} -DWITHOUT_MROONGA_STORAGE_ENGINE=ON"
  if [[ "${TYPE}" == "Debug" ]]; then
    CMAKE_OPT="${CMAKE_OPT} -DWITHOUT_TOKUDB_STORAGE_ENGINE=ON"
  fi
fi

if which ccache ; then
  CMAKE_OPT="${CMAKE_OPT} -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
fi

set +v +x
