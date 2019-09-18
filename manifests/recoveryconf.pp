#
# @overview It requires to have **pg_basebackup** and the defined username already created on the master DB
#
class postgresql::recoveryconf(
                                $masterhost               = undef,
                                $masterusername           = undef,
                                $masterpassword           = undef,
                                $masterport               = $postgresql::params::port_default,
                                $datadir                  = $postgresql::datadir,
                                $restore_command          = undef,
                                $archive_cleanup_command  = undef,
                                $recovery_min_apply_delay = undef,
                                $primary_slot_name        = undef,
                              ) inherits postgresql::params {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  if($datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$postgresql::version]
  }
  else
  {
    $datadir_path = $datadir
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
    command => "bash -xc 'pg_basebackup -D ${datadir_path} -h ${masterhost} -p ${masterport} -U ${masterusername} -w -v -X stream > $(dirname ${datadir_path})/.streaming_replication_init.log 2>&1'",
    user    => $postgresql::params::postgresuser,
    creates => "${datadir_path}/recovery.conf",
    require => File["${postgresql::params::postgreshome}/.pgpass"],
    before  => Class['::postgresql::config'],
    timeout => 0,
  }
  -> Exec <| tag == 'post-recoveryconf' |>
  -> File <| tag == 'post-recoveryconf' |>

  file { "${datadir_path}/recovery.conf":
    ensure  => 'present',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresgroup,
    mode    => '0600',
    content => template("${module_name}/recoveryconf.erb"),
    require => Exec['init streaming replication'],
    before  => Class['::postgresql::config'],
  }
}
