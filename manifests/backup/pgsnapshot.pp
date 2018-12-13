define postgresql::backup::pgsnapshot (
                                      $ensure              = 'present',
                                      $username            = 'postgres',
                                      $backupname          = $name,
                                      $mailto              = undef,
                                      $idhost              = undef,
                                      $basedir             = '/usr/local/bin',
                                      $confdir             = '/etc',
                                      $lvm_disk            = undef,
                                      $aws                 = false,
                                      $snap_size           = '5G',
                                      $keeplvmsnaps        = '2',
                                      $keep_aws_snaps_days = '7',
                                      $snapshot_basename   = 'pgsnap',
                                      $logdir              = '/var/log/pgsnapshot',
                                      $force_ami           = undef,
                                      #cron
                                      $setcronjob          = true,
                                      $hour_cronjob        = '2',
                                      $minute_cronjob      = '0',
                                      $month_cronjob       = undef,
                                      $monthday_cronjob    = undef,
                                      $weekday_cronjob     = undef,
                                    ) {

  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  include ::python
  include ::lvm

  pythonpip { 'psutil':
    ensure => 'present',
  }

  pythonpip { 'boto3':
    ensure => 'present',
  }
  # python-pip
  # pip psutil

  exec { "mkdir p ${basedir} pgsnapshot":
    command => "mkdir -p ${basedir}",
    creates => $basedir,
  }

  exec { "mkdir p ${confdir} pgsnapshot":
    command => "mkdir -p ${confdir}",
    creates => $confdir,
  }


  #source => "puppet:///modules/${module_name}/backup_pgdump.sh",
  file { "${basedir}/pgsnapshot.py":
    ensure  => $ensure,
    owner   => 'root',
    group   => $username,
    mode    => '0750',
    content => file("${module_name}/pgsnapshot/pgsnapshot.py"),
    require => Exec["mkdir p ${basedir} pgsnapshot"],
  }

  file { "${confdir}/postgres_snapshot.config":
    ensure  => $ensure,
    owner   => 'root',
    group   => $username,
    mode    => '0640',
    content => template("${module_name}/backup/config_pgsnapshot.erb"),
    require => Exec["mkdir p ${confdir} pgsnapshot"],
  }

  exec { "mkdir p ${logdir} pgsnapshot":
    command => "mkdir -p ${logdir}",
    creates => $logdir,
  }

  file { $logdir:
    ensure  => 'directory',
    owner   => 'root',
    group   => $username,
    mode    => '0770',
    require => Exec["mkdir p ${logdir} pgsnapshot"],
  }

  if($setcronjob)
  {
    cron { "cronjob logical postgres backup pgsnapshot: ${backupname}":
      ensure   => $ensure,
      command  => "${basedir}/pgsnapshot.py -c ${confdir}/postgres_snapshot.config",
      user     => $username,
      hour     => $hour_cronjob,
      minute   => $minute_cronjob,
      month    => $month_cronjob,
      monthday => $monthday_cronjob,
      weekday  => $weekday_cronjob,
      require  => File[ [ "${confdir}/postgres_snapshot.config",
                          "${basedir}/pgsnapshot.py"
                      ] ],
    }
  }

}
