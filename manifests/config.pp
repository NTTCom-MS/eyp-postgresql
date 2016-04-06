# == Class: postgresql
#
# === postgresql::config documentation
#
class postgresql::config(
                          $version=$postgresql::params::version_default,
                          $datadir=$postgresql::params::datadir_default,
                          $listen='*',
                          $port='5432',
                          $max_connections='100',
                          $wal_level='hot_standby',
                          $max_wal_senders='0',
                          $checkpoint_segments='3',
                          $wal_keep_segments='0',
                          $hot_standby=false,
                        ) inherits postgresql::params {

  file { "${datadir}/postgresql.conf":
    ensure  => 'present',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresgroup,
    mode    => '0600',
    content => template("${module_name}/postgresconf.erb"),
  }

  concat { "${datadir}/pg_hba.conf":
    ensure  => 'present',
    owner   => $postgresql::params::postgresuser,
    group   => $postgresql::params::postgresgroup,
    mode    => '0600',
    content => template("${module_name}/pghba.erb"),
  }

}
