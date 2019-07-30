class postgresql::client(
                          $version = $postgresql::params::version_default,
                        ) inherits postgresql::params {

  include ::postgresql::repo

  package { $postgresql::params::packagename_client[$version]:
    ensure  => 'installed',
    require => Package[$postgresql::params::reponame[$version]],
  }
}
