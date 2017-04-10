# This rotates a number of logs of MariaDB
#
# Logs need to be enabled in @sysconfdir@/my.cnf
# or a config file under @sysconf2dir@
#
# See the settings:
# * log_output
# * log_basename
# * log_error
# * slow_query_log
# * slow_query_log_file
# * general_log
# * general_log_file
#
# Ensure the files specified below match the MariaDB server settings.
#
# Also in one of the configuration files add the following
# group with a user/password as desired.
# [mysqladmin.logrotate]
# user= logrotateuser
# password = <secret> 
#
# where "<secret>" is the password. 
#
# Ensure this user has the approprate permissions to rotate the
# log:
# CREATE USER logrotateuser@localhost IDENTIFIED BY "<secret>";
# GRANT RELOAD ON *.* TO logrotateuser@localhost;
#
# ATTENTION: This config file should be readable ONLY for root !

@localstatedir@/*.err
@localstatedir@/mysqld.log
@localstatedir@/*general.log
@localstatedir@/*-slow.log {
        shared
        notifempty
	weekly
        rotate 4
        missingok
        compress
    postrotate
	# just if mysqld is really running
	if test -x @bindir@/mysqladmin && \
	   @bindir@/mysqladmin --defaults-group-suffix=logrotate ping &>/dev/null
	then
	   @bindir@/mysqladmin --defaults-group-suffix=logrotate --local flush-error-log \
              flush-engine-log flush-general-log flush-slow-log
	fi
    endscript
}
