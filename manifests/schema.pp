define postgresql::schema (
                            $owner,
                            $schemaname = $name,
                            $port       = $postgresql::port,
                          ) {

  Postgresql_psql {
    port => $port,
  }

  postgresql_psql { "CREATE SCHEMA ${schemaname}":
    command => "CREATE SCHEMA ${schemaname} AUTHORIZATION ${owner}",
    unless  => "SELECT nspname FROM pg_namespace WHERE nspname='${schemaname}'",
    require => [ Postgresql::Role[$owner], Class['::postgresql::service'] ],
  }

  postgresql_psql { "ALTER SCHEMA ${schemaname} OWNER TO ${owner}":
    command => "ALTER SCHEMA \"${schemaname}\" OWNER TO ${owner}",
    unless  => "SELECT 1 FROM pg_namespace JOIN pg_roles rol ON nspowner = rol.oid WHERE nspname = '${schemaname}' AND rolname = '${owner}'",
    require => Postgresql_psql["CREATE SCHEMA ${schemaname}"],
  }

  if defined(Postgresql::Role[$owner])
  {
    Postgresql::Role[$owner] -> Postgresql_psql["ALTER SCHEMA ${schemaname} OWNER TO ${owner}"]
  }
}
