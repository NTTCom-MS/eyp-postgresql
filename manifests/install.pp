# == Class: postgresql
#
# === postgresql::install documentation
#
class postgresql::install (
                            $version=$postgresql::params::version_default,
                            $datadir=$postgresql::params::datadir_default,
                          ) inherits postgresql::params {

  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  package { $postgresql::params::reponame[$version]:
    ensure   => 'installed',
    source   => $postgresql::params::reposource[$version],
    provider => $postgresql::params::repoprovider,
  }

  package { $postgresql::params::packagename:
    ensure  => 'installed',
    require => Package[$postgresql::params::reponame[$version]],
  }

  exec { "mkdir p ${datadir}":
    command => "mkdir -p ${datadir}",
    creates => $datadir,
    require => Package[$postgresql::params::packagename],
  }

  file { $datadir:
    ensure  => 'directory',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresgroup,
    mode    => '0700',
    require => Exec["mkdir p ${datadir}"],
  }

  #initdb
  #com a postgres
  #-bash-4.1$ PGDATA="/var/lib/pgsql/9.2/data" /usr/pgsql-9.2/bin/initdb
  #creates => /var/lib/pgsql/9.2/data/pg_hba.conf
  exec { 'initdb postgresql':
    command     => $postgresql::params::initdb[$version],
    environment => "PGDATA=${datadir}",
    user        => $postgresql::params::postgresuser,
    creates     => "${datadir}/pg_hba.conf",
    require     => [File[$datadir], Package[$postgresql::params::packagename]],
  }

  if(defined(Class['sysctl']))
  {
    sysctl::set { 'vm.overcommit_memory':
      value  => '2',
      before => Exec['initdb postgresql'],
    }
  }

}
