class postgresql::checks(
                          $ensure  = 'present',
                          $basedir = '/usr/local/bin',
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
}
