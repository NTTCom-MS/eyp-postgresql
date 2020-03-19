class postgresql::checks(
                          $ensure         = 'present',
                          $basedir        = '/usr/local/bin',
                          $add_nrpe_sudos = true,
                        ) inherits postgresql::params {
  exec { "mkdir p ${basedir}":
    command => "mkdir -p ${basedir}",
    creates => $basedir,
    path    => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  file { "${basedir}/check_replication_lag":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file("${module_name}/nagios/check_replication_lag.sh"),
    require => Exec["mkdir p ${basedir}"],
  }

  file { "${basedir}/check_postgres_datadir":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file("${module_name}/nagios/check_postgres_datadir.sh"),
    require => Exec["mkdir p ${basedir}"],
  }

  if($add_nrpe_sudos)
  {
    nrpe::sudo { 'sudo NRPE check_replication_lag':
      command => "${basedir}/check_replication_lag",
    }

    nrpe::sudo { 'sudo NRPE check_postgres_datadir':
      command => "${basedir}/check_postgres_datadir",
    }
  }
}
