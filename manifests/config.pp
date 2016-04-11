# == Class: postgresql
#
# === postgresql::config documentation
#
# ==== pg_hba concat order
# 00: header
# 01-99: user defined rules
class postgresql::config(
                          $version                         = $postgresql::params::version_default,
                          $datadir                         = $postgresql::params::datadir_default,
                          $listen                          = '*',
                          $port                            = $postgresql::params::port_default,
                          $max_connections                 = '100',
                          $wal_level                       = 'hot_standby',
                          $max_wal_senders                 = '0',
                          $checkpoint_segments             = '3',
                          $wal_keep_segments               = '0',
                          $hot_standby                     = false,
                          $pidfile                         = $postgresql::params::servicename[$version],
                          $log_directory                   = $postgresql::params::log_directory_default,
                          $log_filename                    = $postgresql::params::log_filename_default,
                          $track_activities                = true,
                          $track_counts                    = true,
                          $autovacuum                      = true,
                          $autovacuum_vacuum_scale_factor  = '0.0',
                          $autovacuum_vacuum_threshold     = '5000',
                          $autovacuum_analyze_scale_factor = '0.0',
                          $autovacuum_analyze_threshold    = '5000',
                          $timezone                        = $postgresql::params::timezone_default,
                          $log_timezone                    = $postgresql::params::timezone_default,
                          $superuser_reserved_connections  = '5',
                        ) inherits postgresql::params {

  concat { "${datadir}/postgresql.conf":
    ensure  => 'present',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresgroup,
    mode    => '0600',
  }

  concat::fragment{ "base postgresql ${datadir}":
    target  => "${datadir}/postgresql.conf",
    content => template("${module_name}/postgresconf.erb"),
    order   => '00',
  }

  concat { "${datadir}/pg_hba.conf":
    ensure  => 'present',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresgroup,
    mode    => '0600',
  }

  concat::fragment{ "header pg_hba ${datadir}":
    target  => "${datadir}/pg_hba.conf",
    content => template("${module_name}/hba/header.erb"),
    order   => '00',
  }

}
