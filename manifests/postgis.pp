class postgresql::postgis (
                            $version,
                            $dbname  = undef,
                            $port    = $postgresql::port,
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
        port    => $port,
        require => Package[$postgresql::params::postgis[$version]],
      }
    }
  }
}
