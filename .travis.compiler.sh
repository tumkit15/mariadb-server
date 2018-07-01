#!/bin/bash
set -v -x
CMAKE_OPT=()

# Exclude modules from build not directly affecting the current
# test suites found in $MYSQL_TEST_SUITES, to conserve job time
# as well as disk usage

function exclude_modules() {
  # excludes for all
  CMAKE_OPT+=(-DPLUGIN_TOKUDB=NO -DPLUGIN_MROONGA=NO -DPLUGIN_SPIDER=NO -DPLUGIN_OQGRAPH=NO -DPLUGIN_PERFSCHEMA=NO -DPLUGIN_SPHINX=NO)
  # exclude storage engines not being tested in current job
  if [[ ! "${MYSQL_TEST_SUITES}" =~ "archive" ]]; then
    CMAKE_OPT+=(-DPLUGIN_ARCHIVE=NO)
  fi
  if [[ ! "${MYSQL_TEST_SUITES}" =~ "rocksdb" ]]; then
    CMAKE_OPT+=(-DPLUGIN_ROCKSDB=NO)
  fi
}

if [[ "${TRAVIS_OS_NAME}" == 'linux' ]]; then
  TEST_CASE_TIMEOUT=2
  exclude_modules
  ccache --max-size=1200M

  if [[ "${CXX}" == 'clang++' ]]; then
    case "${CC_VERSION}" in
      7*)
        V=7
        ;;
      *)
        V=${CC_VERSION}.0
        ;;
      *)
    esac
    export CC=clang-${V}
    export CXX=clang++-${V}
    CMAKE_OPT+=(-DCMAKE_AR=/usr/bin/llvm-ar-${V} -DCMAKE_RANLIB=/usr/bin/llvm-ranlib-${V})
    ld=/usr/bin/ld.lld-${V}
    for lang in C CXX
    do
      #CMAKE_OPT+=(-DCMAKE_${lang}_CREATE_SHARED_LIBRARY="${ld} <CMAKE_SHARED_LIBRARY_${lang}_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_${lang}_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
      #CMAKE_OPT+=(-DCMAKE_${lang}_LINK_EXECUTABLE="${ld} <FLAGS> <CMAKE_${lang}_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>")
      CMAKE_OPT+=(-DCMAKE_${lang}_CREATE_SHARED_LIBRARY="${ld} <LINK_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
      CMAKE_OPT+=(-DCMAKE_${lang}_LINK_EXECUTABLE="${ld} <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>")
    done
  elif [[ "${CXX}" == 'g++' ]]; then
    export CXX=g++-${CC_VERSION}
    export CC=gcc-${CC_VERSION}
    if [[ ${CC_VERSION} == 7 ]]; then
      V=2.26
      CMAKE_OPT+=(-DCMAKE_AR=/usr/bin/ar-${V} -DCMAKE_RANLIB=/usr/bin/ranlib-${V})
      ld=/usr/bin/ld.gold-${V}
      for lang in C CXX
      do
        CMAKE_OPT+=(-DCMAKE_${lang}_CREATE_SHARED_LIBRARY="${ld} <LINK_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
        CMAKE_OPT+=(-DCMAKE_${lang}_LINK_EXECUTABLE="${ld} <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>")
      done
    fi
  fi
  if [[ ${CC_VERSION} == 7 ]]; then
    wget http://mirrors.kernel.org/ubuntu/pool/universe/p/percona-xtradb-cluster-galera-2.x/percona-xtradb-cluster-galera-2.x_165-0ubuntu1_amd64.deb ;
    ar vx percona-xtradb-cluster-galera-2.x_165-0ubuntu1_amd64.deb
    tar -xJvf data.tar.xz
    export WSREP_PROVIDER=$PWD/usr/lib/libgalera_smm.so
    MYSQL_TEST_SUITES="${MYSQL_TEST_SUITES},wsrep"
  fi
fi

if [[ "${TRAVIS_OS_NAME}" == 'osx' ]]; then
  TEST_CASE_TIMEOUT=20
  exclude_modules;
  CMAKE_OPT+=(-DOPENSSL_ROOT_DIR=/usr/local/opt/openssl)
fi

if which ccache ; then
  CMAKE_OPT+=(-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache)
fi

set +v +x
