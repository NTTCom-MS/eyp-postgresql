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
    if($postgresql::params::fix_systemd_pg_ctlcluster)
    {
      # Error: /usr/lib/postgresql/11/bin/pg_ctl /usr/lib/postgresql/11/bin/pg_ctl start -D /var/postgres/datadir
      # -l /var/log/postgresql/postgresql-11-main.log
      # -D /var/postgres/datadir/ -s -o
      # -c unix_socket_directories="/var/run/postgresql"
      # -c config_file="/etc/postgresql/11/main/postgresql.conf"
      # -c hba_file="/etc/postgresql/11/main/pg_hba.conf"
      # -c ident_file="/etc/postgresql/11/main/pg_ident.conf"
      # -c external_pid_file="/var/run/postgresql/11-main.pid"  exited with status 1:

      # file { '/etc/postgresql/11/main/pg_hba.conf':
      #   ensure => 'link',
      #   target => "${datadir_path}/pg_hba.conf",
      # }
      # TO AVOID CRICULAR DEPENDENCY:
      exec { 'ln hba raspberry':
        command => "ln -f -s ${datadir_path}/pg_hba.conf /etc/postgresql/${postgresql::version}/main/pg_hba.conf",
        unless  => "ls -l /etc/postgresql/${postgresql::version}/main/pg_hba.conf | grep ${datadir_path}/pg_hba.conf",
        path    => '/usr/sbin:/usr/bin:/sbin:/bin',
      }

      file { "/etc/postgresql/${postgresql::version}/main/postgresql.conf":
        ensure => 'link',
        target => "${datadir_path}/postgresql.conf",
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
