class postgresql::postgis (
                            $version       = $postgresql::version,
                            $datadir       = $postgresql::datadir,
                            $track_utility = true,
                            $track         = 'all',
                            $max           = '10000',
                          ) inherits postgresql::params {
  if($postgresql::params::postgis[$version]==undef)
  {
    fail('unable to install postgis - unsupported version')
  }

  if($datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$version]
  }
  else
  {
    $datadir_path = $datadir
  }

  if(!defined(Package[$postgresql::params::contrib[$version]]))
  {
    package { $postgresql::params::contrib[$version]:
      ensure  => 'installed',
      require => Class['::postgresql::config'],
      before  => Class['::postgresql::service'],
    }
  }

  #https://postgis.net/install/

  postgresql::extension { 'postgis': }
  postgresql::extension { 'postgis_topology': }
  postgresql::extension { 'postgis_sfcgal': }
  postgresql::extension { 'fuzzystrmatch': }
  postgresql::extension { 'address_standardizer': }
  postgresql::extension { 'address_standardizer_data_us': }
  postgresql::extension { 'postgis_tiger_geocoder': }

}
