# == Class: postgresql
#
# === postgresql documentation
#
class postgresql(
                  #general
                  $version             = $postgresql::params::version_default,
                  $datadir             = $postgresql::params::datadir_default,
                  # install
                  $initdb              = true,
                  # config
                  $listen              = ['*'],
                  $port                = $postgresql::params::port_default,
                  $max_connections     = '100',
                  $wal_level           = 'hot_standby',
                  $max_wal_senders     = '0',
                  $checkpoint_segments = '3',
                  $wal_keep_segments   = '0',
                  $hot_standby         = false,
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
    version             => $version,
    datadir             => $datadir,
    listen              => $listen,
    port                => $port,
    max_connections     => $max_connections,
    wal_level           => $wal_level,
    max_wal_senders     => $max_wal_senders,
    checkpoint_segments => $checkpoint_segments,
    wal_keep_segments   => $wal_keep_segments,
    hot_standby         => $hot_standby,
  } ~>

  class { '::postgresql::service':
    version        => $version,
    manage_service => $manage_service,
  } ->

  Class['::postgresql']

}
