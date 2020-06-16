class postgresql::pgbouncer::config inherits postgresql::pgbouncer {

  concat { '/etc/pgbouncer/pgbouncer.ini':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  concat::fragment{ 'base pgbouncer':
    order   => '00',
    target  => '/etc/pgbouncer/pgbouncer.ini',
    content => template("${module_name}/pgbouncer/pgbouncer.erb"),
  }

  concat { '/etc/pgbouncer/pgbouncer-databases.ini':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  concat::fragment{ 'base pgbouncer databases':
    order   => '00',
    target  => '/etc/pgbouncer/pgbouncer-databases.ini',
    content => template("${module_name}/pgbouncer/databases-header.erb"),
  }

  concat { '/etc/pgbouncer/userlist.txt':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  if($postgresql::pgbouncer::realize_dbs_tag!=undef)
  {
    Postgresql::Pgbouncer::Database <| tag == $postgresql::pgbouncer::realize_dbs_tag |>
  }

  if($postgresql::pgbouncer::realize_users_tag!=undef)
  {
    Postgresql::Pgbouncer::Username <| tag == $postgresql::pgbouncer::realize_dbs_tag |>
  }

  if($postgresql::pgbouncer::set_pgbouncer_password!=undef)
  {
    postgresql::role { 'pgbouncer':
      password => $postgresql::pgbouncer::set_pgbouncer_password,
      db_host  => $postgresql::pgbouncer::dbhost_pgbouncer,
    }

    #user_authentication-sql.erb
    file { '/etc/pgbouncer/.user_authentication.sql':
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/pgbouncer/user_authentication-sql.erb"),
    }

    postgresql_psql { 'pgbouncer user_authentication':
      command => '/etc/pgbouncer/.user_authentication.sql',
      unless  => 'SELECT p.proname FROM pg_proc p WHERE p.proname=\'user_authentication\'',
      require => [ Class['::postgresql::service'], File['/etc/pgbouncer/.user_authentication.sql'] ],
    }

  }
}
