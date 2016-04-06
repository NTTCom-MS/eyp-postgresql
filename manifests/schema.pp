define postgresql::schema (
                            $owner,
                            $schemaname=$name
                          ) {

  postgresql_psql { "CREATE SCHEMA ${schemaname}":
    command => "CREATE SCHEMA ${schemaname} AUTHORIZATION ${owner}",
    unless  => "SELECT nspname FROM pg_namespace WHERE nspname='${schemaname}'",
    require => Postgresql::Role[$owner],
  }
}
