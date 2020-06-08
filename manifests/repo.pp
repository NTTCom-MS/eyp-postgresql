class postgresql::repo(
                        $version = $postgresql::params::version_default,
                      ) inherits postgresql::params {
  if($postgresql::params::repoprovider=='rpm')
  {
    package { $postgresql::params::reponame[$version]:
      ensure   => 'installed',
      source   => $postgresql::params::reposource[$version],
      provider => $postgresql::params::repoprovider,
    }
  }
  elsif ($postgresql::params::repoprovider=='apt')
  {
    include ::apt

    #  deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main
    apt::source { 'pgdg':
      location => 'http://apt.postgresql.org/pub/repos/apt/',
      release  => "${::lsbdistcodename}-pgdg",
      repos    => 'main',
    }

    apt::key { 'pgdg':
      key        => '690A171644E1C59F7E5E68775492644846BBC421',
      key_source => 'https://www.postgresql.org/media/keys/ACCC4CF8.asc',
    }
  }
  # raspbian no te repo
}
