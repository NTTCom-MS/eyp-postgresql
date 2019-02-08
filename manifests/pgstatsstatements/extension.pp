define postgresql::pgstatsstatements::extension($dbname = $name) {
  #https://postgis.net/install/

  postgresql::extension { 'pg_stat_statements':
    dbname => $dbname,
  }
}
