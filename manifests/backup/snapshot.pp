define postgresql::backup::snapshot (
                                      $destination,
                                      $ensure           = 'present',
                                      $username         = 'postgres',
                                      $backupname       = $name,
                                      $retention        = '7',
                                      $mailto           = undef,
                                      $idhost           = undef,
                                      $basedir          = '/usr/local/bin',
                                      #cron
                                      $setcronjob       = true,
                                      $hour_cronjob     = '2',
                                      $minute_cronjob   = '0',
                                      $month_cronjob    = undef,
                                      $monthday_cronjob = undef,
                                      $weekday_cronjob  = undef,
                                    ) {

  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  validate_absolute_path($basedir)
  validate_absolute_path($destination)

  #source => "puppet:///modules/${module_name}/backup_pgdump.sh",
  file { "${basedir}/postgres_snapshot.py":
    ensure  => $ensure,
    owner   => 'root',
    group   => $username,
    mode    => '0750',
    content => file("${module_name}/backup_snapshot.py"),
  }

  file { "${basedir}/postgres_snapshot.config":
    ensure  => $ensure,
    owner   => 'root',
    group   => $username,
    mode    => '0640',
    content => template("${module_name}/backup/backup_pgdump_config.erb"),
  }

  exec { "mkdir p ${destination} backup":
    command => "mkdir -p ${destination}",
    creates => $destination,
  }

  file { $destination:
    ensure  => 'directory',
    owner   => 'root',
    group   => $username,
    mode    => '0770',
    require => Exec["mkdir p ${destination} backup"],
  }

  if($setcronjob)
  {
    cron { "cronjob logical postgres backup: ${backupname}":
      ensure   => $ensure,
      command  => "${basedir}/pgdumbackup_snapshotpbackup.py",
      user     => $username,
      hour     => $hour_cronjob,
      minute   => $minute_cronjob,
      month    => $month_cronjob,
      monthday => $monthday_cronjob,
      weekday  => $weekday_cronjob,
      require  => File[ [ "${basedir}/postgres_snapshot.config",
                          "${basedir}/postgres_snapshot.py"
                      ] ],
    }
  }

}
