# == Class: postgresql
#
# === postgresql documentation
#
class postgresql(
                  #general
                  $version                         = $postgresql::params::version_default,
                  $datadir                         = $postgresql::params::datadir_default,
                  # install
                  $initdb                          = true,
                  # config
                  $listen                          = [ '*' ],
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
                  # service
                  $manage_service      = true,
                ) inherits postgresql::params {

  validate_array($listen)

  class { '::postgresql::install':
    version => $version,
    datadir => $datadir,
    initdb  => $initdb,
  } ->

  class { '::postgresql::config':
    version                         => $version,
    datadir                         => $datadir,
    listen                          => $listen,
    port                            => $port,
    max_connections                 => $max_connections,
    wal_level                       => $wal_level,
    max_wal_senders                 => $max_wal_senders,
    checkpoint_segments             => $checkpoint_segments,
    wal_keep_segments               => $wal_keep_segments,
    hot_standby                     => $hot_standby,
    log_directory                   => $log_directory,
    log_filename                    => $log_filename,
    track_activities                => $track_activities,
    track_counts                    => $track_counts,
    autovacuum                      => $autovacuum,
    autovacuum_vacuum_scale_factor  => $autovacuum_vacuum_scale_factor,
    autovacuum_vacuum_threshold     => $autovacuum_vacuum_threshold,
    autovacuum_analyze_scale_factor => $autovacuum_analyze_scale_factor,
    autovacuum_analyze_threshold    => $autovacuum_analyze_threshold,
    timezone                        => $timezone,
    log_timezone                    => $log_timezone,
  } ~>

  class { '::postgresql::service':
    version        => $version,
    manage_service => $manage_service,
  } ->

  Class['::postgresql']

}
