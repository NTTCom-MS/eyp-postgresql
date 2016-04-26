# == Class: postgresql
#
# === postgresql::config documentation
#
# ==== pg_hba concat order
# 00: header
# 01-99: user defined rules
# ==== postgres.conf concat order
# 00: base
# 80: pg_stats_statements
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
                          $pidfile                         = $postgresql::params::servicename[$postgresql::params::version_default],
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
                          $archive_mode                     = false,
                          $archive_command                  = '',
                          $archive_timeout                  = '0',
                          $maintenance_work_mem             = '10MB',
                          $wal_buffers                      = '-1',
                          $work_mem                         = '8MB',
                          $shared_buffers                   = sprintf('%dMB',ceiling(sprintf('%f', $::memorysize_mb)*4)),
                          $lc_messages                      = 'C',
                          $lc_monetary                      = 'en_US.UTF-8',
                          $lc_numeric                       = 'en_US.UTF-8',
                          $lc_time                          = 'en_US.UTF-8',
                          $default_text_search_config       = 'pg_catalog.english',
                          $shared_preload_libraries         = undef,
                        ) inherits postgresql::params {

  Postgresql_psql {
    port => $port,
  }

  concat { "${datadir}/postgresql.conf":
    ensure => 'present',
    owner  => $postgresql::params::postgresuser,
    group  => $postgresql::params::postgresgroup,
    mode   => '0600',
  }

  concat::fragment{ "base postgresql ${datadir}":
    target  => "${datadir}/postgresql.conf",
    content => template("${module_name}/postgresconf.erb"),
    order   => '00',
  }

  concat { "${datadir}/pg_hba.conf":
    ensure => 'present',
    owner  => $postgresql::params::postgresuser,
    group  => $postgresql::params::postgresgroup,
    mode   => '0600',
  }

  concat::fragment{ "header pg_hba ${datadir}":
    target  => "${datadir}/pg_hba.conf",
    content => template("${module_name}/hba/header.erb"),
    order   => '00',
  }

  if($sysconfig)
  {
    file { "/etc/sysconfig/pgsql/${servicename[$version]}":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "PGPORT=${port}\n",
    }
  }

}
