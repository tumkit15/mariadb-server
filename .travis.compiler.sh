#!/bin/sh
set -v -x
CFLAGS="-fstack-protector-all"
if [[ "${TRAVIS_OS_NAME}" == 'linux' ]]; then
  if [[ "${CXX}" == 'clang++' ]]; then
    CMAKE_OPT="-DWITHOUT_TOKUDB_STORAGE_ENGINE=ON -DWITHOUT_MROONGA_STORAGE_ENGINE=ON"
    CMAKE_OPT="${CMAKE_OPT} -DWITH_ASAN=ON"
    case ${GCC_VERSION} in
      5) CXX=clang++-3.9 ;;
      6) CXX=clang++-4.0 ;;
    esac
    export CXX CC=${CXX/++/}
    if which ccache ; then
      CMAKE_OPT="${CMAKE_OPT} -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
      # Make ccache enabled for clang when cmake isn't new enough to recognise launcher
      mkdir -p "${HOME}/bin"
      CCACHE=`which ccache`
      for compiler in ${CXX} ${CC} ; do
        ln -s "${CCACHE}" "${compiler}"
      done
      export PATH="${HOME}/bin:${PATH}"
    fi
    CFLAGS="${CFLAGS} -fsanitize=undefined -fsanitize=integer -fsanitize=nullability"
  elif [[ "${CXX}" == 'g++' ]]; then
    export CXX=g++-${GCC_VERSION}
    export CC=gcc-${GCC_VERSION}
    CMAKE_OPT=""
    if [[ ${GCC_VERSION} != 4.8 ]]; then
      CFLAGS="${CFLAGS} -fsanitize=undefined"
    fi
    if [[ ${GCC_VERSION} != 5 ]]; then
      CMAKE_OPT="${CMAKE_OPT} -DWITH_ASAN=ON"
    fi
    if [[ ${GCC_VERSION} == 6 ]]; then
      if [[ ! -f "${HOME}"/galera/libgalera_smm.so ]]; then
        mkdir -p "${HOME}"/galera
        wget http://mirrors.kernel.org/ubuntu/pool/universe/p/percona-xtradb-cluster-galera-2.x/percona-xtradb-cluster-galera-2.x_165-0ubuntu1_amd64.deb
        ar vx percona-xtradb-cluster-galera-2.x_165-0ubuntu1_amd64.deb
        tar -xJvf data.tar.xz  --strip-components=3 ./usr/lib/libgalera_smm.so -C "${HOME}"/galera
      fi
      export WSREP_PROVIDER="${HOME}"/galera/libgalera_smm.so
      MYSQL_TEST_SUITES="${MYSQL_TEST_SUITES},wsrep"
    fi
  fi
else
  # osx_image based tests
  CMAKE_OPT="-DOPENSSL_ROOT_DIR=/usr/local/opt/openssl"
  CMAKE_OPT="${CMAKE_OPT} -DWITH_ASAN=ON"
  CFLAGS="${CFLAGS} -fsanitize=undefined"
  if which ccache ; then
    CMAKE_OPT="${CMAKE_OPT} -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
  fi
  CMAKE_OPT="${CMAKE_OPT} -DWITHOUT_MROONGA_STORAGE_ENGINE=ON"
  if [[ "${TYPE}" == "Debug" ]]; then
    CMAKE_OPT="${CMAKE_OPT} -DWITHOUT_TOKUDB_STORAGE_ENGINE=ON"
  fi
fi

# main.mysqlhotcopy_myisam consitently failed in travis containers
# https://travis-ci.org/grooverdan/mariadb-server/builds/217661580
echo 'main.mysqlhotcopy_myisam : unstable in containers' >> ${TRAVIS_BUILD_DIR}/mysql-test/unstable-tests
echo 'archive.mysqlhotcopy_archive : unstable in containers' >> ${TRAVIS_BUILD_DIR}/mysql-test/unstable-tests

# https://github.com/google/sanitizers/wiki/AddressSanitizerFlags
export TSAN_OPTIONS="atexit=1"
# http://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html
export  UBSAN_OPTIONS=print_stacktrace=1

export CFLAGS
export CXXFLAGS="${CFLAGS}"
set +v +x
