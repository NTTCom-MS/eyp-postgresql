# == Class: postgresql
#
# === postgresql::config documentation
#
class postgresql::config(
                          $version=$postgresql::params::version_default,
                          $datadir=$postgresql::params::datadir_default,
                        ) inherits postgresql::params {

  file { "${datadir}/postgresql.conf":
    ensure  => 'present',
    owner   => $postgresql::paranms::postgresuser,
    group   => $postgresql::paranms::postgresuser,
    mode    => '0600',
    content => template("${module_name}/postgresconf.erb"),
  }

}
