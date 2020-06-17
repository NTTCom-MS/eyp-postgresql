# postgres=# select * from pg_roles;
#        rolname       | rolsuper | rolinherit | rolcreaterole | rolcreatedb | rolcanlogin | rolreplication | rolconnlimit | rolpassword | rolvaliduntil | rolbypassrls |                   rolconfig
#    |  oid
# (...)
define postgresql::role (
                          $password,
                          $rolename       = $name,
                          $login          = true,
                          $superuser      = false,
                          $replication    = false,
                          $inherit        = true,
                          $db_host        = undef,
                          $port           = $postgresql::port,
                          $pgbouncer_tag  = undef,
                        ) {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  Postgresql_psql {
    port => $port,
  }

  $password_hash_md5=md5("${password}${rolename}")
  $password_hash_sql="md5${password_hash_md5}"
  $password_sql="ENCRYPTED PASSWORD '${password}'"

  if($pgbouncer_tag!=undef)
  {
    @postgresql::pgbouncer::username { $rolename:
      password_md5 => $password_hash_sql,
      tag => $pgbouncer_tag,
    }
  }

  postgresql_psql { "ALTER ROLE ${rolename} ENCRYPTED PASSWORD":
    command => "ALTER ROLE \"${rolename}\" ${password_sql}",
    unless  => "SELECT usename FROM pg_shadow WHERE usename='${rolename}' and passwd='${password_hash_sql}'",
    require => [Class['::postgresql::service'], Postgresql_psql["CREATE ROLE ${rolename}"]],
  }

  $login_sql=$login ? { true => 'LOGIN', default => 'NOLOGIN' }

  postgresql_psql {"ALTER ROLE \"${rolename}\" ${login_sql}":
    unless  => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}' and rolcanlogin=${login}",
    require => [Class['::postgresql::service'], Postgresql_psql["CREATE ROLE ${rolename}"]],
    host    => $db_host,
  }

  $superuser_sql=$superuser ? { true => 'SUPERUSER', default => 'NOSUPERUSER' }

  postgresql_psql {"ALTER ROLE \"${rolename}\" ${superuser_sql}":
    unless  => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}' and rolsuper=${superuser}",
    require => [Class['::postgresql::service'], Postgresql_psql["CREATE ROLE ${rolename}"]],
    host    => $db_host,
  }

  $replication_sql=$replication ? { true => 'REPLICATION', default => '' }

  postgresql_psql {"ALTER ROLE \"${rolename}\" ${replication_sql}":
    unless  => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}' and rolreplication=${replication}",
    require => [Class['::postgresql::service'], Postgresql_psql["CREATE ROLE ${rolename}"]],
    host    => $db_host,
  }

  $inherit_sql = $inherit ? { true => 'INHERIT', default => 'NOINHERIT' }
  postgresql_psql {"ALTER ROLE \"${rolename}\" ${inherit_sql}":
    unless  => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}' and rolinherit=${inherit}",
    require => [Class['::postgresql::service'], Postgresql_psql["CREATE ROLE ${rolename}"]],
    host    => $db_host,
  }

  #
  # CREATE ROLE
  #

  postgresql_psql { "CREATE ROLE ${rolename}":
    command => "CREATE ROLE ${rolename} ${login_sql} ${superuser_sql} ${replication_sql} ${password_sql} ${inherit_sql};",
    unless  => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}'",
    require => Class['::postgresql::service'],
    host    => $db_host,
  }

}
