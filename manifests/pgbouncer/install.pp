class postgresql::pgbouncer::install inherits postgresql::pgbouncer {

  if($postgresql::pgbouncer::manage_package)
  {
    package { $postgresql::params::pgbouncer_package_name:
      ensure => $postgresql::pgbouncer::package_ensure,
    }
  }

}
