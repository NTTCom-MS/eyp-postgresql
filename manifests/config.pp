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
                          $datadir                         = undef,
                          $listen                          = '*',
                          $port                            = $postgresql::params::port_default,
                          $max_connections                 = '100',
                          $wal_level                       = 'hot_standby',
                          $max_wal_senders                 = '0',
                          $checkpoint_segments             = '3',
                          $wal_keep_segments               = '0',
                          $hot_standby                     = false,
                          $pidfile                         = undef,
                          $log_directory                   = $postgresql::params::log_directory_default,
                          $log_filename                    = $postgresql::params::log_filename_default,
                          $track_activities                = true,
                          $track_counts                    = true,
                          $autovacuum                      = true,
                          $autovacuum_vacuum_scale_factor  = '0.0',
                          $autovacuum_vacuum_threshold     = '5000',
                          $autovacuum_analyze_scale_factor = '0.0',
                          $autovacuum_analyze_threshold    = '5000',
                          $autovacuum_freeze_max_age       = undef,
                          $log_autovacuum_min_duration     = '-1',
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
                          $search_path                      = [ '"$user"', 'public' ],
                          $log_min_duration_statement       = '-1',
                          $log_file_mode                    = '0600',
                        ) inherits postgresql::params {

  Postgresql_psql {
    port => $port,
  }

  if($datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$version]
  }
  else
  {
    $datadir_path = $datadir
  }

  if($pidfile==undef)
  {
    $pidfilename=$postgresql::params::pidfile[$version]
  }
  else
  {
    $pidfilename=$pidfile
  }

  # postgres >= 9.5
  # max_wal_size = (3 * checkpoint_segments) * 16MB

  if($postgresql::params::systemd)
  {
    systemd::service::dropin { $postgresql::params::servicename[$version]:
      env_vars => [ "PGDATA=${datadir_path}" ],
    }
  }


  concat { "${datadir_path}/postgresql.conf":
    ensure => 'present',
    owner  => $postgresql::params::postgresuser,
    group  => $postgresql::params::postgresgroup,
    mode   => '0600',
  }

  concat::fragment{ "base postgresql ${datadir_path}":
    target  => "${datadir_path}/postgresql.conf",
    content => template("${module_name}/postgresconf.erb"),
    order   => '00',
  }

  concat { "${datadir_path}/pg_hba.conf":
    ensure => 'present',
    owner  => $postgresql::params::postgresuser,
    group  => $postgresql::params::postgresgroup,
    mode   => '0600',
  }

  concat::fragment{ "header pg_hba ${datadir_path}":
    target  => "${datadir_path}/pg_hba.conf",
    content => template("${module_name}/hba/header.erb"),
    order   => '00',
  }

  if($postgresql::params::sysconfig)
  {
    file { "/etc/sysconfig/pgsql/${postgresql::params::servicename[$version]}":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "PGPORT=${port}\n",
    }
  }

  file { '/etc/profile.d/psql.sh':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "alias psql='psql -p ${port}'\n",
  }

}
