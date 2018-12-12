class postgresql::backup::pgsnaprestore (
                                          $basedir = '/usr/local/bin',
                                        ) inherits postgresql::params {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  file { "${basedir}/pgsnaprestore.sh":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => file("${module_name}/pgsnapshot/pgsnaprestore.sh"),
  }
}
