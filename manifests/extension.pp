define postgresql::extension(
                              $extension_name = $name,
                              $port           = undef,
                            ) {

  Postgresql_psql {
    port => $port,
  }

  postgresql_psql { "CREATE EXTENSION ${extension_name}":
    command => "CREATE EXTENSION ${extension_name}",
    unless  => "SELECT extname FROM pg_extension WHERE extname='${extension_name}'",
    require => Class['::postgresql::service'],
  }
}
