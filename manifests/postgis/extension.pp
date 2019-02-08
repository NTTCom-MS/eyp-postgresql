define postgresql::postgis::extension($dbname = $name) {
  #https://postgis.net/install/

  postgresql::extension { 'postgis':
    dbname => $dbname,
  }

  postgresql::extension { 'postgis_topology':
    dbname => $dbname,
  }

  postgresql::extension { 'postgis_sfcgal':
    dbname => $dbname,
  }

  postgresql::extension { 'fuzzystrmatch':
    dbname => $dbname,
  }

  postgresql::extension { 'address_standardizer':
    dbname => $dbname,
  }

  postgresql::extension { 'address_standardizer_data_us':
    dbname => $dbname,
  }

  postgresql::extension { 'postgis_tiger_geocoder':
    dbname => $dbname,
  }
}
