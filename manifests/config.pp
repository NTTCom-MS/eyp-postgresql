# == Class: postgresql
#
# === postgresql::config documentation
#
# ==== pg_hba concat order
# 00: header
# 01-99: user defined rules
# ==== postgres.conf concat order
# 00: base
# 80: pg_stats_statements
class postgresql::config inherits postgresql {

  Postgresql_psql {
    port => $postgresql::port,
  }

  if($postgresql::datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$version]
  }
  else
  {
    $datadir_path = $postgresql::datadir
  }

  if($postgresql::pidfile==undef)
  {
    $pidfilename=$postgresql::params::pidfile[$version]
  }
  else
  {
    $pidfilename=$postgresql::pidfile
  }

  # postgres >= 9.5
  # max_wal_size = (3 * checkpoint_segments) * 16MB

  if($postgresql::params::systemd)
  {
    systemd::service::dropin { $postgresql::params::servicename[$version]:
      env_vars => [ "PGDATA=${datadir_path}" ],
    }
  }

  if($postgresql::manage_configfile)
  {
    concat { "${datadir_path}/postgresql.conf":
      ensure => 'present',
      owner  => $postgresql::params::postgresuser,
      group  => $postgresql::params::postgresgroup,
      mode   => '0600',
    }

    concat::fragment{ "base postgresql ${datadir_path}":
      target  => "${datadir_path}/postgresql.conf",
      content => template("${module_name}/postgresconf.erb"),
      order   => '00',
    }
  }

  if($postgresql::manage_pghba)
  {
    concat { "${datadir_path}/pg_hba.conf":
      ensure => 'present',
      owner  => $postgresql::params::postgresuser,
      group  => $postgresql::params::postgresgroup,
      mode   => '0600',
    }

    concat::fragment{ "header pg_hba ${datadir_path}":
      target  => "${datadir_path}/pg_hba.conf",
      content => template("${module_name}/hba/header.erb"),
      order   => '00',
    }
  }

  if($postgresql::params::sysconfig)
  {
    file { "/etc/sysconfig/pgsql/${postgresql::params::servicename[$version]}":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "PGPORT=${postgresql::port}\n",
    }
  }

  file { '/etc/profile.d/psql.sh':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "alias psql='psql -p ${postgresql::port}'\n",
  }

}
