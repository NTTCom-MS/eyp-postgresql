# == Class: postgresql
#
# === postgresql::install documentation
#
class postgresql::install (
                            $version           = $postgresql::params::version_default,
                            $datadir           = $postgresql::params::datadir_default,
                            $initdb            = true,
                            $overcommit_memory = '2',
                            $shmmax            = undef,
                            $shmall            = undef,
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

  if($initdb)
  {
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

    $before_initdb=Exec['initdb postgresql']
  }
  else
  {
    $before_initdb=undef
  }

  if(defined(Class['sysctl']))
  {
    if($overcommit_memory!=undef)
    {
      sysctl::set { 'vm.overcommit_memory':
        value  => $overcommit_memory,
        before => $before_initdb,
      }
    }

    # shared memory
    #
    # The default maximum segment size is 32 MB, which is only adequate for
    # very small PostgreSQL installations.
    # The default maximum total size is 2097152 pages
    #
    # SHMMAX 	Maximum size of shared memory segment (bytes) 	at least several megabytes (see text)
    # 3/4 of the physical memory
    # $ sysctl -w kernel.shmmax=17179869184
    #
    # SHMALL 	Total amount of shared memory available (bytes or pages) 	if bytes, same as SHMMAX; if pages, ceil(SHMMAX/PAGE_SIZE)
    # if bytes, same as SHMMAX, if pages, ceil(SHMMAX/PAGE_SIZE)
    # $ sysctl -w kernel.shmall=4194304
    #

  }

}
