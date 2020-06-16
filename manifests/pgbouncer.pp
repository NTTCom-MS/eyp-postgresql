class postgresql::pgbouncer (
                $manage_package         = true,
                $package_ensure         = 'installed',
                $manage_service         = true,
                $manage_docker_service  = true,
                $service_ensure         = 'running',
                $service_enable         = true,
                $auth_type              = 'md5',
                $enable_auth_query      = false,
                $auth_query             = 'SELECT usename, passwd FROM user_authentication($1)',
                $listen_addr            = '127.0.0.1',
                $listen_port            = '6432',
                $logfile                = '/var/log/pgbouncer/pgbouncer.log',
                $pool_mode              = 'session',
                $realize_dbs_tag        = undef,
                $realize_users_tag      = undef,
                $set_pgbouncer_password = undef,
                $dbhost_pgbouncer       = '127.0.0.1',
                $src_ip_pgbouncer       = '127.0.0.1',
              ) inherits postgresql::params {

  class { '::postgresql::pgbouncer::install': } ->
  class { '::postgresql::pgbouncer::config': } ~>
  class { '::postgresql::pgbouncer::service': } ->
  Class['::postgresql::pgbouncer']

}
