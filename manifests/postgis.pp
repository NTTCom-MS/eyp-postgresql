class postgresql::postgis (
                            $version       = '25_10',
                            $datadir       = $postgresql::datadir,
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
      require => Class[ [ '::postgresql::config', '::epel' ] ],
      before  => Class['::postgresql::service'],
    }
  }
}
