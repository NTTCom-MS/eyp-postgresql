# == Class: postgresql
#
# === postgresql::install documentation
#
class postgresql::install (
                            $version           = $postgresql::params::version_default,
                            $datadir           = $postgresql::datadir,
                            $initdb            = true,
                            $overcommit_memory = '2',
                            $shmmax            = ceiling(sprintf('%f', $::memorysize_mb)*786432),
                            $shmall            = ceiling(ceiling(sprintf('%f', $::memorysize_mb)*786432)/$::eyp_postgresql_pagesize),
                          ) inherits postgresql::params {

  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  if($datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$version]
  }
  else
  {
    $datadir_path = $datadir
  }

  package { $postgresql::params::reponame[$version]:
    ensure   => 'installed',
    source   => $postgresql::params::reposource[$version],
    provider => $postgresql::params::repoprovider,
  }

  package { $postgresql::params::packagename[$version]:
    ensure  => 'installed',
    require => Package[$postgresql::params::reponame[$version]],
  }

  exec { "mkdir p ${datadir_path}":
    command => "mkdir -p ${datadir_path}",
    creates => $datadir_path,
    require => Package[$postgresql::params::packagename[$version]],
  }

  # FATAL:  data directory "/var/lib/pgsql/9.2/data" has group or world access
  # DETAIL:  Permissions should be u=rwx (0700).
  # [root@evx2401660 9.2]# ls -la
  # total 28
  # drwx------  6 postgres postgres 4096 Apr 27 10:48 .
  # drwx------  4 postgres postgres 4096 Apr 26 16:39 ..
  # drwx------  2 postgres postgres 4096 Mar 29 22:42 backups
  # drwxr-xr-x 15 postgres postgres 4096 Apr 27 10:48 data
  # drwx------  2 root     root     4096 Apr 27 10:50 lost+found
  # -rw-------  1 postgres postgres 2094 Apr 27 10:50 pgstartup.log
  # drwxr-xr-x  3 postgres postgres 4096 Apr 27 10:36 tablespaces
  # [root@evx2401660 9.2]# chmod 700 /var/lib/pgsql/9.2/data

  file { $datadir_path:
    ensure  => 'directory',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresgroup,
    mode    => '0700',
    require => Exec["mkdir p ${datadir_path}"],
  }

  if($initdb)
  {
    #initdb
    #com a postgres
    #-bash-4.1$ PGDATA="/var/lib/pgsql/9.2/data" /usr/pgsql-9.2/bin/initdb
    #creates => /var/lib/pgsql/9.2/data/pg_hba.conf
    exec { 'initdb postgresql':
      command     => $postgresql::params::initdb[$version],
      environment => "PGDATA=${datadir_path}",
      user        => $postgresql::params::postgresuser,
      creates     => "${datadir_path}/pg_hba.conf",
      require     => [File[$datadir_path], Package[$postgresql::params::packagename[$version]]],
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
    # SHMMAX   Maximum size of shared memory segment (bytes)   at least several megabytes (see text)
    # 3/4 of the physical memory
    # $ sysctl -w kernel.shmmax=17179869184
    #

    if($shmmax!=undef)
    {
      sysctl::set { 'kernel.shmmax':
        value  => $shmmax,
        before => $before_initdb,
      }
    }

    #
    # SHMALL   Total amount of shared memory available (bytes or pages)   if bytes, same as SHMMAX; if pages, ceil(SHMMAX/PAGE_SIZE)
    # if bytes, same as SHMMAX, if pages, ceil(SHMMAX/PAGE_SIZE)
    # $ sysctl -w kernel.shmall=4194304
    #

    if($shmall!=undef)
    {
      sysctl::set { 'kernel.shmall':
        value  => $shmall,
        before => $before_initdb,
      }
    }

  }

}
