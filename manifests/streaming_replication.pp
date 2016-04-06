class postgresql::streaming_replication (
                                          $masterhost,
                                          $masterusername,
                                          $masterpassword,
                                          $masterport=$postgresql::params::port_default,
                                          $datadir = $postgresql::params::datadir_default
                                        ) inherits postgresql::params {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  file { '/root/.pgpass':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "${masterhost}:${masterport}:postgres:${masterusername}:${masterpassword}\n",
    require => Class['::postgresql::install'],
  }

  exec { 'init streaming replication':
    command => "bash -c 'pg_basebackup -D ${datadir} -h ${masterhost} -p ${masterport} -U ${masterusername} -w -v > ${datadir}/.streaming_replication_init.log 2>&1'",
    user    => $postgresql::params::postgresuser,
    creates => "${datadir}/.streaming_replication_init.log",
    require => File['/root/.pgpass'],
    before  => Class['::postgresql::service'],
  }
}
