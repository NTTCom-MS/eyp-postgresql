class postgresql::install inherits postgresql {

  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  if($postgresql::datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$postgresql::version]
  }
  else
  {
    $datadir_path = $postgresql::datadir
  }

  file { '/usr/local/bin/check_postgres_pending_restart':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template("${module_name}/check_postgres_pending_restart.erb"),
  }

  package { $postgresql::params::reponame[$postgresql::version]:
    ensure   => 'installed',
    source   => $postgresql::params::reposource[$postgresql::version],
    provider => $postgresql::params::repoprovider,
  }

  package { $postgresql::params::packagename[$postgresql::version]:
    ensure  => 'installed',
    require => Package[$postgresql::params::reponame[$postgresql::version]],
  }

  exec { "mkdir p ${datadir_path}":
    command => "mkdir -p ${datadir_path}",
    creates => $datadir_path,
    require => Package[$postgresql::params::packagename[$postgresql::version]],
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

  if($postgresql::initdb)
  {
    #initdb
    #com a postgres
    #-bash-4.1$ PGDATA="/var/lib/pgsql/9.2/data" /usr/pgsql-9.2/bin/initdb
    #creates => /var/lib/pgsql/9.2/data/pg_hba.conf
    exec { 'initdb postgresql':
      command     => $postgresql::params::initdb[$postgresql::version],
      environment => "PGDATA=${datadir_path}",
      user        => $postgresql::params::postgresuser,
      creates     => "${datadir_path}/pg_hba.conf",
      require     => [File[$datadir_path], Package[$postgresql::params::packagename[$postgresql::version]]],
    }

    $before_initdb=Exec['initdb postgresql']
  }
  else
  {
    $before_initdb=undef
  }

  #
  # pg_log: compression
  #

  if($postgresql::set_gzip_pglog_cronjob)
  {
    $ensure_gzip_pglog_cronjob = 'present'
  }
  else
  {
    $ensure_gzip_pglog_cronjob = 'absent'
  }

  cron { 'postgresql cronjob gzip_pglog_cronjob':
    ensure   => $ensure_gzip_pglog_cronjob,
    command  => "find ${postgresql::datadir}/pg_log -type f -iname \\*log -mtime +${postgresql::maxdays_gzip_pglog_cronjob} -exec gzip -${postgresql::gzip_level_pglog_cronjob} {} \\;",
    user     => 'root',
    hour     => $hour_gzip_pglog_cronjob,
    minute   => $minute_gzip_pglog_cronjob,
    month    => $month_gzip_pglog_cronjob,
    monthday => $monthday_gzip_pglog_cronjob,
    weekday  => $weekday_gzip_pglog_cronjob,
  }

  #
  # pg_log: purge old logs
  #

  if($postgresql::set_purge_pglog_cronjob)
  {
    $ensure_purge_pglog_cronjob='present'
  }
  else
  {
    $ensure_purge_pglog_cronjob='absent'
  }

  cron { 'postgresql cronjob purge_pglog_cronjob':
    ensure   => $ensure_purge_pglog_cronjob,
    command  => "find ${postgresql::datadir}/pg_log -type f -mtime +${postgresql::maxdays_purge_pglog_cronjob} -delete",
    user     => 'root',
    hour     => $hour_purge_pglog_cronjob,
    minute   => $minute_purge_pglog_cronjob,
    month    => $month_purge_pglog_cronjob,
    monthday => $monthday_purge_pglog_cronjob,
    weekday  => $weekday_purge_pglog_cronjob,
  }

  if(defined(Class['sysctl']))
  {
    if($postgresql::overcommit_memory!=undef)
    {
      sysctl::set { 'vm.overcommit_memory':
        value  => $postgresql::overcommit_memory,
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

    if($postgresql::shmmax!=undef)
    {
      sysctl::set { 'kernel.shmmax':
        value  => $postgresql::shmmax,
        before => $before_initdb,
      }
    }

    #
    # SHMALL   Total amount of shared memory available (bytes or pages)   if bytes, same as SHMMAX; if pages, ceil(SHMMAX/PAGE_SIZE)
    # if bytes, same as SHMMAX, if pages, ceil(SHMMAX/PAGE_SIZE)
    # $ sysctl -w kernel.shmall=4194304
    #

    if($postgresql::shmall!=undef)
    {
      sysctl::set { 'kernel.shmall':
        value  => $postgresql::shmall,
        before => $before_initdb,
      }
    }
  }
}
