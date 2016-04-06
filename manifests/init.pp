# == Class: postgresql
#
# === postgresql documentation
#
class postgresql(
                  #general
                  $version=$postgresql::params::version_default,
                  $datadir=$postgresql::params::datadir_default,
                  # install
                  # config
                  $listen=['*'],
                  $port='5432',
                  $max_connections='100',
                  $wal_level='hot_standby',
                  # service
                  $manage_service=true,
                ) inherits postgresql::params {

  validate_array($listen)

  class { '::postgresql::install':
    version => $version,
    datadir => $datadir,
  } ->

  class { '::postgresql::config':
    version         => $version,
    datadir         => $datadir,
    listen          => $listen,
    port            => $port,
    max_connections => $max_connections,
    wal_level       => $wal_level,
  } ~>

  class { '::postgresql::service':
    manage_service => $manage_service,
  } ->

  Class['::postgresql']

}
