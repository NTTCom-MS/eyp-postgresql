define postgresql::db (
                        $owner,
                        $dbname              = $name,
                        $port                = $postgresql::port,
                        $pgbouncer_tag       = undef,
                        $pgbouncer_addr      = '127.0.0.1',
                        $pgbouncer_auth_user = 'pgbouncer',
                      ) {

  Postgresql_psql {
    port => $port,
  }

  postgresql_psql { "CREATE DATABASE ${dbname}":
    command => "CREATE DATABASE ${dbname} OWNER ${owner}",
    unless  => "SELECT datname FROM pg_database WHERE datname='${dbname}'",
    require => [ Postgresql::Role[$owner], Class['::postgresql::service'] ],
  }

  postgresql_psql { "ALTER DATABASE ${dbname} OWNER TO ${owner}":
    command => "ALTER DATABASE \"${dbname}\" OWNER TO ${owner}",
    unless  => "SELECT 1 FROM pg_database JOIN pg_roles rol ON datdba = rol.oid WHERE datname = '${dbname}' AND rolname = '${owner}'",
    require => Postgresql_psql["CREATE DATABASE ${dbname}"],
  }

  if defined(Postgresql::Role[$owner])
  {
    Postgresql::Role[$owner] -> Postgresql_psql["ALTER DATABASE ${dbname} OWNER TO ${owner}"]
  }

  if($pgbouncer_tag!=undef)
  {
    @postgresql::pgbouncer::database { "pgbouncer-${dbname}-${pgbouncer_addr}-${pgbouncer_tag}":
      host            => $pgbouncer_addr,
      username        => $pgbouncer_auth_user,
      port            => $port,
      database        => $dbname,
      remote_database => $dbname,
      tag             => $pgbouncer_tag,
    }
  }
}
