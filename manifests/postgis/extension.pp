define postgresql::postgis::extension (
                                        $dbname = $name,
                                        $port   = $postgresql::port,
                                      ) {
  #https://postgis.net/install/

  postgresql::extension { 'postgis':
    dbname => $dbname,
    port   => $port,
  }

  postgresql::extension { 'postgis_topology':
    dbname => $dbname,
    port   => $port,
  }

  postgresql::extension { 'postgis_sfcgal':
    dbname => $dbname,
    port   => $port,
  }

  postgresql::extension { 'fuzzystrmatch':
    dbname => $dbname,
    port   => $port,
  }

  postgresql::extension { 'address_standardizer':
    dbname => $dbname,
    port   => $port,
  }

  postgresql::extension { 'address_standardizer_data_us':
    dbname => $dbname,
    port   => $port,
  }

  postgresql::extension { 'postgis_tiger_geocoder':
    dbname => $dbname,
    port   => $port,
  }
}
