class postgresql::postgis (
                            $version       = '25_10',
                            $datadir       = $postgresql::datadir,
                            $track_utility = true,
                            $track         = 'all',
                            $max           = '10000',
                          ) inherits postgresql::params {
  if($postgresql::params::postgis[$version]==undef)
  {
    fail('unable to install postgis - unsupported version')
  }

  include ::epel

  if($datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$version]
  }
  else
  {
    $datadir_path = $datadir
  }

  if(!defined(Package[$postgresql::params::postgis[$version]]))
  {
    package { $postgresql::params::postgis[$version]:
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
