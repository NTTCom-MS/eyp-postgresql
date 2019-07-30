class postgresql::repo(
                        $version = $postgresql::params::version_default,
                      ) inherits postgresql::params {
  package { $postgresql::params::reponame[$version]:
    ensure   => 'installed',
    source   => $postgresql::params::reposource[$version],
    provider => $postgresql::params::repoprovider,
  }
}
