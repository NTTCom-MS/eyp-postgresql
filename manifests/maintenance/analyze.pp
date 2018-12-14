class postgresql::maintenance::analyze (
                                          $ensure  = 'present',
                                          $basedir = '/usr/local/bin',
                                          #cron - by default weekly every saturday
                                          $setcronjob          = true,
                                          $hour_cronjob        = '2',
                                          $minute_cronjob      = '0',
                                          $month_cronjob       = undef,
                                          $monthday_cronjob    = undef,
                                          $weekday_cronjob     = '6',
                                        ) inherits postgresql::params {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  file { "${basedir}/analyze.sh":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => file("${module_name}/vacuum_analyze.sh"),
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
