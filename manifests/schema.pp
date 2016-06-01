define postgresql::schema (
                            $owner,
                            $schemaname = $name,
                            $port       = undef,
                          ) {

  Postgresql_psql {
    port => $port,
  }

  postgresql_psql { "CREATE SCHEMA ${schemaname}":
    command => "CREATE SCHEMA ${schemaname} AUTHORIZATION ${owner}",
    unless  => "SELECT nspname FROM pg_namespace WHERE nspname='${schemaname}'",
    require => [ Postgresql::Role[$owner], Class['::postgresql::service'] ],
  }
}
