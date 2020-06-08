class postgresql::client(
                          $version = $postgresql::params::version_default,
                        ) inherits postgresql::params {

  include ::postgresql::repo

  if($postgresql::params::repoprovider!='raspbian10')
  {
    package { $postgresql::params::packagename_client[$version]:
      ensure  => 'installed',
      require => Class['::postgresql::repo'],
    }
  }
}
