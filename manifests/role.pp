define postgresql::role (
                          $password,
                          $rolename    = $name,
                          $login       = true,
                          $superuser   = false,
                          $replication = false,
                        ) {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  $password_hash_md5=md5("${password}${rolename}")
  $password_hash_sql="md5${password_hash_md5}"
  $password_sql="ENCRYPTED PASSWORD '${password}'"

  postgresql_psql { "ALTER ROLE ${rolename} ENCRYPTED PASSWORD":
    command     => "ALTER ROLE \"${rolename}\" ${password_sql}",
    unless      => "SELECT usename FROM pg_shadow WHERE usename='${rolename}' and passwd='${password_hash_sql}'",
  }

  $login_sql=$login ? { true => 'LOGIN', default => 'NOLOGIN' }

  postgresql_psql {"ALTER ROLE \"${rolename}\" ${login_sql}":
    unless => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}' and rolcanlogin=${login}",
  }

  $superuser_sql=$superuser ? { true => 'SUPERUSER', default => 'NOSUPERUSER' }

  postgresql_psql {"ALTER ROLE \"${rolename}\" ${superuser_sql}":
    unless => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}' and rolsuper=${superuser}",
  }

  $replication_sql=$replication ? { true => 'REPLICATION', default => '' }

  postgresql_psql {"ALTER ROLE \"${rolename}\" ${replication_sql}":
    unless => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}' and rolreplication=${replication}",
  }

  #
  # CREATE ROLE
  #

  postgresql_psql { "CREATE ROLE ${rolename}":
    command => "CREATE ROLE ${rolename} ${login_sql} ${superuser_sql} ${replication_sql} ${password_sql};",
    unless  => "SELECT rolname FROM pg_roles WHERE rolname='${rolename}'",
  }

}
