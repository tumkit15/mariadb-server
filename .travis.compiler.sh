#!/bin/sh
if [[ "${TRAVIS_OS_NAME}" == 'linux' && "${CXX}" == 'clang++' ]]; then
  case ${GCC_VERSION} in
    4.8) MYSQL_BUILD_CXX=clang++-3.8; MYSQL_TEST_SUITES=main,optimizer_unfixed_bugs,parts,sys_vars,unit,vcol,innodb,innodb_gis,innodb_zip,innodb_fts ;;
    5) MYSQL_BUILD_CXX=clang++-3.9; MYSQL_TEST_SUITES=binlog,binlog_encryption,encryption ;;
    6) MYSQL_BUILD_CXX=clang++-4.0; MYSQL_TEST_SUITES=csv,federated,funcs_1,funcs_2,gcol,handler,heap,json,maria,percona,perfschema,plugins,multi_source,roles ;;
# missing default suites: archive,rpl,wsrep
  esac
  export MYSQL_TEST_SUITES
  export MYSQL_BUILD_CXX MYSQL_BUILD_CC=${MYSQL_BUILD_CXX/++/} MYSQL_COMPILER_LAUNCHER=ccache
elif [[ "${TRAVIS_OS_NAME}" == 'linux' && "${CXX}" == 'g++' ]]; then
  export MYSQL_BUILD_CXX=g++-${GCC_VERSION};
  export MYSQL_BUILD_CC=gcc-${GCC_VERSION}
fi
# main.mysqlhotcopy_myisam consitently failed in travis containers
# https://travis-ci.org/grooverdan/mariadb-server/builds/217661580
echo 'main.mysqlhotcopy_myisam : unstable in containers' | tee -a debian/unstable-tests.amd64
