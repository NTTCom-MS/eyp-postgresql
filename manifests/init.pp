# == Class: postgresql
#
# === postgresql documentation
#
class postgresql(
                  $version='9.2',
                  $datadir=$postgresql::params::datadir_default,
                ) inherits postgresql::params {

  package { $postgresql::params::reponame[$version]:
    ensure   => 'installed',
    source   => $postgresql::params::reposource[$version],
    provider => $postgresql::params::repoprovider,
  }

  package { $postgresql::params::packagename:
    ensure  => 'installed',
    require => Package[$postgresql::params::reponame[$version]],
  }

  #initdb
  #com a postgres
  #-bash-4.1$ PGDATA="/var/lib/pgsql/9.2/data" /usr/pgsql-9.2/bin/initdb
  #creates => /var/lib/pgsql/9.2/data/pg_hba.conf

  # service definition and notification:
  #
  # notify => Class['postgresql::service'],
  # class { 'postgresql::service': }

}
