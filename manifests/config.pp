# == Class: postgresql
#
# === postgresql::config documentation
#
# ==== postgres.conf concat order
# 00: base
# 80: pg_stats_statements
class postgresql::config inherits postgresql {

  Postgresql_psql {
    port => $postgresql::port,
  }

  if($postgresql::datadir==undef)
  {
    if($postgresql::params::repoprovider=='raspbian10')
    {
      $datadir_path='/var/lib/postgresql/11/main'
    }
    else
    {
      $datadir_path=$postgresql::params::datadir_default[$postgresql::version]
    }
  }
  else
  {
    $datadir_path=$postgresql::datadir
  }

  if($postgresql::pidfile==undef)
  {
    $pidfilename=$postgresql::params::pidfile[$postgresql::version]
  }
  else
  {
    $pidfilename=$postgresql::pidfile
  }

  # postgres >= 9.5
  # max_wal_size = (3 * checkpoint_segments) * 16MB

  if($postgresql::params::systemd)
  {
    if($postgresql::params::repoprovider=='raspbian10')
    {
      systemd::service::dropin { 'postgresql@11-main.service':
        execstart => "-/usr/bin/pg_ctlcluster -o -D ${datadir_path} --skip-systemctl-redirect %i start",
        before    => Class['postgresql::service'],
      }

      # root@datalore:/var/lib/postgresql/11/main# cat postmaster.opts
      # /usr/lib/postgresql/11/bin/postgres "-D" "/var/lib/postgresql/11/main" "-c" "config_file=/etc/postgresql/11/main/postgresql.conf"
      file { "${datadir_path}/postmaster.opts":
        ensure  => 'present',
        owner   => $postgresql::params::postgresuser,
        group   => $postgresql::params::postgresgroup,
        mode    => '0600',
        content => "/usr/lib/postgresql/11/bin/postgres \"-D\" \"${datadir_path}\" \"-c\" \"config_file=${datadir_path}/postgresql.conf\"",
      }

    }
    else
    {
      systemd::service::dropin { $postgresql::params::servicename[$postgresql::version]:
        env_vars => [ "PGDATA=${datadir_path}" ],
        before   => Class['postgresql::service'],
      }
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

  if($postgresql::params::sysconfig)
  {
    file { "/etc/sysconfig/pgsql/${postgresql::params::servicename[$postgresql::version]}":
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
