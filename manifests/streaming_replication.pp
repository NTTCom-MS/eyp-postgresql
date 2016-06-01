class postgresql::streaming_replication (
                                          $masterhost     = undef,
                                          $masterusername = undef,
                                          $masterpassword = undef,
                                          $masterport     = $postgresql::params::port_default,
                                          $datadir        = $postgresql::params::datadir_default
                                        ) inherits postgresql::params {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  if($masterhost==undef or $masterusername==undef or $masterpassword==undef)
  {
    fail("masterhost (${masterhost}), masterusername (${masterusername}) and masterpassword (${masterpassword}) are required")
  }

  #TODO: postgres home

  file { "${postgresql::params::postgreshome}/.pgpass":
    ensure  => 'present',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresuser,
    mode    => '0600',
    content => "${masterhost}:${masterport}:*:${masterusername}:${masterpassword}\n",
    require => Class['::postgresql::install'],
  }

  exec { 'init streaming replication':
    command => "bash -xc 'pg_basebackup -D ${datadir} -h ${masterhost} -p ${masterport} -U ${masterusername} -w -v -X stream > $(dirname ${datadir})/.streaming_replication_init.log 2>&1'",
    user    => $postgresql::params::postgresuser,
    creates => "${datadir}/recovery.conf",
    require => File["${postgresql::params::postgreshome}/.pgpass"],
    before  => Class['::postgresql::config'],
  }

  file { "${datadir}/recovery.conf":
    ensure  => 'present',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresgroup,
    mode    => '0600',
    content => template("${module_name}/streamingreplication.erb"),
    require => Exec['init streaming replication'],
    before  => Class['::postgresql::config'],
  }
}
