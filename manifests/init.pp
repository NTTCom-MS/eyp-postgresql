# TODO: log_min_duration_statement
# HINT:  Valid units for this parameter are "kB", "MB", "GB", and "TB".
#
# @summary postgres installation class
#
# @param version version to install
# @param datadir datadir to use
# @param initdb boolean, set it to true to create datadir's directies. In a standby server with streaming replication you want to set it to false
# @param overcommit_memory modes available:
#   undef: do not change it,
#   0: heuristic overcommit (this is the default),
#   1: always overcommit, never check,
#   2: always check, never
# @param shmmax maximum size of shared memory segment
# @param shmall total amount of shared memory available
# @param manage_service set it to true to manage PostgreSQL's service
# @param archive_command_custom custom archive command
# @param archive_dir archive dir, if archive_command_custom is undef, it will be:
#   test ! -f ${archive_dir}/%f && cp %p ${archive_dir}/%f
# @param archive_dir_user archive dir user
# @param archive_dir_group archive dir group
# @param archive_dir_mode archive dir mode
# @param archive_dir_chmod chmod to this mask if using archive_dir
#
class postgresql(
                  #general
                  $version                         = $postgresql::params::version_default,
                  $datadir                         = undef,
                  # install
                  $install_contrib                 = false,
                  $initdb                          = true,
                  $overcommit_memory               = '2',
                  $shmmax                          = ceiling(sprintf('%f', $::memorysize_mb)*786432),
                  $shmall                          = ceiling(ceiling(sprintf('%f', $::memorysize_mb)*786432)/$::eyp_postgresql_pagesize),
                  $set_gzip_pglog_cronjob          = true,
                  $maxdays_gzip_pglog_cronjob      = '6',
                  $gzip_level_pglog_cronjob        = '9',
                  $hour_gzip_pglog_cronjob         = '1',
                  $minute_gzip_pglog_cronjob       = '0',
                  $month_gzip_pglog_cronjob        = undef,
                  $monthday_gzip_pglog_cronjob     = undef,
                  $weekday_gzip_pglog_cronjob      = undef,
                  $set_purge_pglog_cronjob         = true,
                  $maxdays_purge_pglog_cronjob     = '30',
                  $hour_purge_pglog_cronjob        = '3',
                  $minute_purge_pglog_cronjob      = '0',
                  $month_purge_pglog_cronjob       = undef,
                  $monthday_purge_pglog_cronjob    = undef,
                  $weekday_purge_pglog_cronjob     = undef,
                  # service
                  $manage_service                  = true,
                  $manage_docker_service           = true,
                  $ensure                          = 'running',
                  $enable                          = true,
                  $restart_if_needed               = true,
                  # config
                  $listen                          = [ '*' ],
                  $port                            = $postgresql::params::port_default,
                  $bonjour                         = false,
                  $bonjour_name                    = '',
                  $max_connections                 = '100',
                  $wal_level                       = 'hot_standby',
                  $max_wal_senders                 = '5',
                  $checkpoint_segments             = '16',
                  $wal_keep_segments               = '0',
                  $pidfile                         = undef,
                  $log_directory                   = $postgresql::params::log_directory_default,
                  $log_filename                    = $postgresql::params::log_filename_default,
                  $log_autovacuum_min_duration     = '-1',
                  $log_timezone                    = $postgresql::params::timezone_default,
                  $log_min_duration_statement      = '-1',
                  $log_file_mode                   = '0600',
                  $track_activities                = true,
                  $track_counts                    = true,
                  $effective_io_concurrency        = '1',
                  $checkpoint_timeout              = '5min',
                  $checkpoint_completion_target    = '0.5',
                  $vacuum_cost_limit               = '200',
                  $autovacuum                      = true,
                  $autovacuum_vacuum_scale_factor  = '0.0',
                  $autovacuum_vacuum_threshold     = '5000',
                  $autovacuum_analyze_scale_factor = '0.0',
                  $autovacuum_analyze_threshold    = '5000',
                  $autovacuum_freeze_max_age       = undef,
                  $autovacuum_naptime              = '1min',
                  $autovacuum_max_workers          = '3',
                  $autovacuum_vacuum_cost_limit    = '-1',
                  $timezone                        = $postgresql::params::timezone_default,
                  $superuser_reserved_connections  = '5',
                  $archive_mode                    = true,
                  $archive_command_custom          = undef,
                  $archive_dir                     = undef,
                  $archive_dir_user                = undef,
                  $archive_dir_group               = undef,
                  $archive_dir_mode                = undef,
                  $archive_dir_chmod               = undef,
                  $archive_timeout                 = '0',
                  $archived_wals_retention         = '+7',
                  $archived_wals_hour              = '0',
                  $archived_wals_minute            = '0',
                  $archived_wals_month             = '*',
                  $archived_wals_monthday          = '*',
                  $archived_wals_weekday           = '*',
                  $maintenance_work_mem            = '64MB',
                  $wal_buffers                     = '-1',
                  $work_mem                        = '8MB',
                  $shared_buffers                  = sprintf('%dMB',ceiling(sprintf('%f', $::memorysize_mb)/4)),
                  $lc_messages                     = 'C',
                  $lc_monetary                     = 'en_US.UTF-8',
                  $lc_numeric                      = 'en_US.UTF-8',
                  $lc_time                         = 'en_US.UTF-8',
                  $default_text_search_config      = 'pg_catalog.english',
                  $shared_preload_libraries        = [],
                  $search_path                     = [ '"$user"', 'public' ],
                  $manage_pghba                    = true,
                  $manage_configfile               = true,
                  $max_replication_slots           = '5',
                  $effective_cache_size            = sprintf('%dMB',ceiling(sprintf('%f', ($::memorysize_mb)/4)*3)),
                  $wal_compression                 = true,
                  $log_line_prefix                 = undef,
                  $log_lock_waits                  = true,
                  $deadlock_timeout                = '1s',
                  $default_transaction_read_only   = false,
                  $max_worker_processes            = $::processorcount,
                  $max_parallel_workers            = $::processorcount,
                  $max_parallel_workers_per_gather = max(2, ceiling(sprintf('%f', ($::processorcount)/2))),
                  $hot_standby                     = false,
                  $max_standby_archive_delay       = '30s',
                  $max_standby_streaming_delay     = '30s',
                  $ensure_nagios_checks            = 'present',
                  $basedir_nagios_checks           = '/usr/local/bin',
                  $add_hba_default_local_rules     = true,
                  $default_local_authmethod        = 'trust',
                ) inherits postgresql::params {

  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  if($pidfile==undef)
  {
    $pidfilename=$postgresql::params::pidfile[$version]
  }
  else
  {
    $pidfilename=$pidfile
  }

  if($datadir==undef)
  {
    $datadir_path=$postgresql::params::datadir_default[$version]
  }
  else
  {
    $datadir_path = $datadir
  }

  if($archive_dir!=undef)
  {
    #tenim un munt de muntatge local, per exemple un NFS pels arxivats
    # validate_absolute_path($archive_dir)

    exec { "mkdir -p ${archive_dir} postgres archive command ${version} ${datadir_path}":
      command => "mkdir -p ${archive_dir}",
      creates => $archive_dir,
      require => Class['::postgresql::install'],
      tag     => 'post-recoveryconf',
    }

    file { $archive_dir:
      ensure => 'directory',
      owner  => $archive_dir_user,
      group  => $archive_dir_group,
      mode   => $archive_dir_mode,
      before => Class['::postgresql::service'],
      tag    => 'post-recoveryconf',
    }

    if($archive_dir!=undef and $archive_command_custom==undef)
    {
      #si no tenim un archive_command_custom definit, fem el default
      if($archive_dir_chmod==undef)
      {
        $archive_command="test ! -f ${archive_dir}/%f && cp --no-preserve=mode,ownership,timestamps ${datadir_path}/%p ${archive_dir}/%f"
      }
      else
      {
        $archive_command="test ! -f ${archive_dir}/%f && cp --no-preserve=mode,ownership,timestamps ${datadir_path}/%p ${archive_dir}/%f && chmod ${archive_dir_chmod} ${archive_dir}/*"
      }
    }
    else
    {
      #sino, el que ens pasin
      $archive_command=$archive_command_custom
    }

    if($archived_wals_retention!=undef)
    {
      #si no definim com undef la retencio, configurem un cron per purgar
      cron { "cronjob purge walls ${$archived_wals_retention} postgres ${archive_dir}":
        ensure   => 'present',
        command  => "find ${archive_dir} -type f -mtime ${archived_wals_retention} -delete",
        user     => 'root',
        hour     => $archived_wals_hour,
        minute   => $archived_wals_minute,
        month    => $archived_wals_month,
        monthday => $archived_wals_monthday,
        weekday  => $archived_wals_weekday,
      }
    }
  }
  else
  {
    #si els arxivats no son locals
    if($archive_command_custom!=undef)
    {
      # pasem el que toqui
      $archive_command=$archive_command_custom
    }
    else
    {
      # segurament es un: i have no idea what i'm doing o son proves, deixem un cd .
      $archive_command='cd .'
    }
  }

  class { '::postgresql::checks':
    ensure  => $ensure_nagios_checks,
    basedir => $basedir_nagios_checks,
  }

  class { '::postgresql::install': }

  class { '::postgresql::config':
    require => Class['::postgresql::install'],
    notify  => Class['::postgresql::config::reload'],
  }

  class { '::postgresql::hba::config':
    require => Class['::postgresql::install'],
    notify  => Class['::postgresql::config::reload'],
  }

  class { '::postgresql::config::reload':
    require => Class['::postgresql::config'],
  }

  class { '::postgresql::service':
    before => Class['::postgresql::config::reload'],
  }

}
