define postgresql::pgstatsstatements::extension (
                                                  $dbname = $name,
                                                  $port   = $postgresql::port,
                                                ) {
  #https://postgis.net/install/

  postgresql::extension { 'pg_stat_statements':
    dbname => $dbname,
    port   => $port,
  }
}
