class postgresql::pgbouncer (
                $manage_package        = true,
                $package_ensure        = 'installed',
                $manage_service        = true,
                $manage_docker_service = true,
                $service_ensure        = 'running',
                $service_enable        = true,
                $auth_type             = 'md5',
              ) inherits postgresql::pgbouncer::params {

  class { '::postgresql::pgbouncer::install': } ->
  class { '::postgresql::pgbouncer::config': } ~>
  class { '::postgresql::pgbouncer::service': } ->
  Class['::postgresql::pgbouncer']

}
