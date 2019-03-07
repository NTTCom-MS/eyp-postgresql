define postgresql::extension(
                              $extension_name = $name,
                              $port           = $postgresql::port,
                              $dbname         = undef,
                            ) {
  Postgresql_psql {
    port => $port,
  }

  if($dbname != undef)
  {
    if defined(Postgresql::Db[$dbname])
    {
      Postgresql::Db[$dbname] -> Postgresql_psql["CREATE EXTENSION ${extension_name}"]
    }
  }

  postgresql_psql { "CREATE EXTENSION ${extension_name}":
    command => "CREATE EXTENSION ${extension_name}",
    unless  => "SELECT extname FROM pg_extension WHERE extname='${extension_name}'",
    db      => $dbname,
    require => Class['::postgresql::service'],
  }
}
