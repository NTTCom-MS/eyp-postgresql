class postgresql::pgstatsstatements (
                                      $version       = $postgresql::params::version_default,
                                      $datadir       = $postgresql::params::datadir_default,
                                      $track_utility = true,
                                      $track         = 'all',
                                      $max           = '10000',
                                    ) inherits postgresql::params {
  #
  if(!defined(Package[$postgresql::params::contrib[$version]]))
  {
    package { $postgresql::params::contrib[$version]:
      ensure => 'installed',
      before => Class['::postgresql::service'],
    }
  }

  concat::fragment{ "pg_stats_statement postgresql ${datadir}":
    target  => "${datadir}/postgresql.conf",
    content => template("${module_name}/pgstatsstatements/pgstatsstatements.erb"),
    order   => '80',
  }

}
