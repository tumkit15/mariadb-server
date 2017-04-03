#!/bin/sh
set -x -v
if [[ "${TRAVIS_OS_NAME}" == 'linux' && "${CXX}" == 'clang++' ]]; then
  CMAKE_OPT="-DWITHOUT_TOKUDB_STORAGE_ENGINE=ON -DWITHOUT_MROONGA_STORAGE_ENGINE=ON";
  case ${GCC_VERSION} in
    4.8) CXX=clang++-3.8; MYSQL_TEST_SUITES=main,optimizer_unfixed_bugs,parts,sys_vars,unit,vcol,innodb,innodb_gis,innodb_zip,innodb_fts ;;
    5) CXX=clang++-3.9; MYSQL_TEST_SUITES=binlog,binlog_encryption,encryption ;;
    6) CXX=clang++-4.0; MYSQL_TEST_SUITES=csv,federated,funcs_1,funcs_2,gcol,handler,heap,json,maria,percona,perfschema,plugins,multi_source,roles ;;
# missing default suites: archive,rpl,wsrep
  esac
  export CXX CC=${CXX/++/}
elif [[ "${TRAVIS_OS_NAME}" == 'linux' && "${CXX}" == 'g++' ]]; then
  CMAKE_OPT=""
  export CXX=g++-${GCC_VERSION}
  export CC=gcc-${GCC_VERSION}
  case ${GCC_VERSION} in
    4.8) MYSQL_TEST_SUITES=rpl ;;
    5)   MYSQL_TEST_SUITES=main,archive ; CMAKE_OPT="${CMAKE_OPT} -DCMAKE_BUILD_TYPE=Debug" ;;
    6)   wget http://mirrors.kernel.org/ubuntu/pool/universe/p/percona-xtradb-cluster-galera-2.x/percona-xtradb-cluster-galera-2.x_165-0ubuntu1_amd64.deb ;
         ar vx percona-xtradb-cluster-galera-2.x_165-0ubuntu1_amd64.deb ;
         tar -xvf data.tar.gz ;
         export WSREP_PROVIDER=$PWD/usr/lib/libgalera_smm.so ;
         MYSQL_TEST_SUITES=wsrep ;;
  esac
else
  # osx_image based tests
  CMAKE_OPT="-DOPENSSL_ROOT_DIR=/usr/local/opt/openssl -DCMAKE_C_COMPILER_LAUNCHER=/usr/local/bin/ccache -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/local/bin/ccache"
  env
  case ${GCC_VERSION} in
    4.8) MYSQL_TEST_SUITES=rpl ;;
    5)   MYSQL_TEST_SUITES=main,archive ; CMAKE_OPT="${CMAKE_OPT} -DCMAKE_BUILD_TYPE=Debug" ;;
    6)   MYSQL_TEST_SUITES=main,innodb ;;
    *)   MYSQL_TEST_SUITES=csv,federated,funcs_1,funcs_2,gcol,handler,heap,json,maria,percona,perfschema,plugins,multi_source,roles ;;
  esac
fi

# main.mysqlhotcopy_myisam consitently failed in travis containers
# https://travis-ci.org/grooverdan/mariadb-server/builds/217661580
echo 'main.mysqlhotcopy_myisam : unstable in containers' | ${TRAVIS_BUILD_DIR}/mysql-test/unstable-tests

set +x +v
