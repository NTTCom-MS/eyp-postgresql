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
                  $initdb                          = true,
                  $overcommit_memory               = '2',
                  $shmmax                          = ceiling(sprintf('%f', $::memorysize_mb)*786432),
                  $shmall                          = ceiling(ceiling(sprintf('%f', $::memorysize_mb)*786432)/$::eyp_postgresql_pagesize),
                  # service
                  $manage_service                  = true,
                  # config
                  $listen                          = [ '*' ],
                  $port                            = $postgresql::params::port_default,
                  $max_connections                 = '100',
                  $wal_level                       = 'hot_standby',
                  $max_wal_senders                 = '0',
                  $checkpoint_segments             = '16',
                  $wal_keep_segments               = '0',
                  $hot_standby                     = false,
                  $pidfile                         = undef,
                  $log_directory                   = $postgresql::params::log_directory_default,
                  $log_filename                    = $postgresql::params::log_filename_default,
                  $track_activities                = true,
                  $track_counts                    = true,
                  $autovacuum                      = true,
                  $autovacuum_vacuum_scale_factor  = '0.0',
                  $autovacuum_vacuum_threshold     = '5000',
                  $autovacuum_analyze_scale_factor = '0.0',
                  $autovacuum_analyze_threshold    = '5000',
                  $autovacuum_freeze_max_age       = undef,
                  $log_autovacuum_min_duration     = '-1',
                  $timezone                        = $postgresql::params::timezone_default,
                  $log_timezone                    = $postgresql::params::timezone_default,
                  $superuser_reserved_connections  = '5',
                  $archive_mode                    = false,
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
                  $maintenance_work_mem            = '10MB',
                  $wal_buffers                     = '-1',
                  $work_mem                        = '8MB',
                  $shared_buffers                  = sprintf('%dMB',ceiling(sprintf('%f', $::memorysize_mb)/4)),
                  $lc_messages                     = 'C',
                  $lc_monetary                     = 'en_US.UTF-8',
                  $lc_numeric                      = 'en_US.UTF-8',
                  $lc_time                         = 'en_US.UTF-8',
                  $default_text_search_config      = 'pg_catalog.english',
                  $shared_preload_libraries        = undef,
                  $search_path                     = [ '"$user"', 'public' ],
                ) inherits postgresql::params {

  validate_array($listen)

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

  if($shared_preload_libraries!=undef)
  {
    validate_array($shared_preload_libraries)
  }

  if($archive_dir!=undef)
  {
    #tenim un munt de muntatge local, per exemple un NFS pels arvhivats
    validate_absolute_path($archive_dir)

    exec { "mkdir -p ${archive_dir} postgres archive command ${version} ${datadir_path}":
      command => "mkdir -p ${archive_dir}",
      creates => $archive_dir,
      require => Class['::postgresql::install'],
      before  => Class['::postgresql::service'],
      tag     => 'post-streaming_replication',
    }

    file { $archive_dir:
      ensure  => 'directory',
      owner   => $archive_dir_user,
      group   => $archive_dir_group,
      mode    => $archive_dir_mode,
      require => Exec["mkdir -p ${archive_dir} postgres archive command ${version} ${datadir_path}"],
      tag     => 'post-streaming_replication',
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


  class { '::postgresql::install':
    version           => $version,
    datadir           => $datadir_path,
    initdb            => $initdb,
    overcommit_memory => $overcommit_memory,
    shmmax            => $shmmax,
    shmall            => $shmall,
  } ->

  class { '::postgresql::config':
    version                         => $version,
    pidfile                         => $pidfilename,
    datadir                         => $datadir_path,
    listen                          => $listen,
    port                            => $port,
    max_connections                 => $max_connections,
    wal_level                       => $wal_level,
    max_wal_senders                 => $max_wal_senders,
    checkpoint_segments             => $checkpoint_segments,
    wal_keep_segments               => $wal_keep_segments,
    hot_standby                     => $hot_standby,
    log_directory                   => $log_directory,
    log_filename                    => $log_filename,
    track_activities                => $track_activities,
    track_counts                    => $track_counts,
    autovacuum                      => $autovacuum,
    autovacuum_vacuum_scale_factor  => $autovacuum_vacuum_scale_factor,
    autovacuum_vacuum_threshold     => $autovacuum_vacuum_threshold,
    autovacuum_analyze_scale_factor => $autovacuum_analyze_scale_factor,
    autovacuum_analyze_threshold    => $autovacuum_analyze_threshold,
    autovacuum_freeze_max_age       => $autovacuum_freeze_max_age,
    log_autovacuum_min_duration     => $log_autovacuum_min_duration,
    timezone                        => $timezone,
    log_timezone                    => $log_timezone,
    superuser_reserved_connections  => $superuser_reserved_connections,
    archive_mode                    => $archive_mode,
    archive_command                 => $archive_command,
    archive_timeout                 => $archive_timeout,
    maintenance_work_mem            => $maintenance_work_mem,
    wal_buffers                     => $wal_buffers,
    work_mem                        => $work_mem,
    shared_buffers                  => $shared_buffers,
    lc_messages                     => $lc_messages,
    lc_monetary                     => $lc_monetary,
    lc_numeric                      => $lc_numeric,
    lc_time                         => $lc_time,
    default_text_search_config      => $default_text_search_config,
    shared_preload_libraries        => $shared_preload_libraries,
  } ~>

  class { '::postgresql::service':
    version        => $version,
    manage_service => $manage_service,
  }

}
