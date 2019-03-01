class postgresql::postgis (
                            $version = '25_10',
                            $dbname  = undef,
                          ) inherits postgresql::params {
  if($postgresql::params::postgis[$version]==undef)
  {
    fail('unable to install postgis - unsupported version')
  }

  include ::epel

  if(!defined(Package[$postgresql::params::postgis[$version]]))
  {
    package { $postgresql::params::postgis[$version]:
      ensure  => 'installed',
      require => Class[ [ '::postgresql::config', '::epel' ] ],
      before  => Class['::postgresql::service'],
    }

    if($dbname!=undef)
    {
      postgresql::postgis::extension{ $dbname:
        require => Package[$postgresql::params::postgis[$version]],
      }
    }
  }
}
