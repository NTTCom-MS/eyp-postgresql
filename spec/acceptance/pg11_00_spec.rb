require 'spec_helper_acceptance'
require_relative './version.rb'

describe 'postgresql class' do

  context 'basic setup postgres 10' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOF

      class { 'postgresql':
    		wal_level           => 'hot_standby',
    		max_wal_senders     => '3',
    		checkpoint_segments => '8',
    		wal_keep_segments   => '8',
        version             => '11',
        port                => '5411',
        archive_dir         => '/archivedir',
    	}

    	postgresql::hba_rule { 'test':
    		user     => 'replicator',
    		database => 'replication',
    		address  => '192.168.56.0/24',
    	}

    	postgresql::role { 'replicator':
    		replication => true,
    		password    => 'replicatorpassword',
    	}

    	postgresql::schema { 'jordi':
    		owner => 'replicator',
    	}

      EOF

      # Run it twice and test for idempotency
      expect(apply_manifest(pp).exit_code).to_not eq(1)
      expect(apply_manifest(pp).exit_code).to eq(0)
    end

    describe package($packagename11) do
      it { is_expected.to be_installed }
    end

    describe service($servicename11) do
      it { should be_enabled }
      it { is_expected.to be_running }
    end

    describe port(5411) do
      it { should be_listening }
    end

    describe file($postgresconf11) do
      it { should be_file }
      its(:content) { should match 'wal_level = hot_standby' }
      its(:content) { should match 'max_connections = 100' }
      its(:content) { should match 'wal_level = hot_standby' }
      its(:content) { should match 'wal_keep_segments = 8' }
      its(:content) { should_not match 'checkpoint_segments = 8' }
      its(:content) { should match 'max_wal_senders = 3' }
      its(:content) { should match 'puppet managed file' }
    end

    describe file($pghba11) do
      it { should be_file }
      its(:content) { should match '# rule: test' }
      its(:content) { should match 'host	replication	replicator	192.168.56.0/24			md5' }
      its(:content) { should match 'puppet managed file' }
    end

    #echo "SELECT nspname FROM pg_namespace WHERE nspname='jordi'" | psql -U postgres | grep jordi
    it "schema jordi" do
      expect(shell("echo \"SELECT nspname FROM pg_namespace WHERE nspname='jordi'\" | psql -U postgres -h 127.0.0.1 -p 5411 | grep jordi").exit_code).to be_zero
    end

    #SELECT rolname FROM pg_roles WHERE rolname=
    it "role replicator" do
      expect(shell("echo \"SELECT rolname FROM pg_roles WHERE rolname='replicator'\" | psql -U postgres -h 127.0.0.1 -p 5411 | grep replicator").exit_code).to be_zero
    end

    it "postgres version" do
      expect(shell("echo \"select version()\" | psql -U postgres -p 5411 | grep \"PostgreSQL 10\"").exit_code).to be_zero
    end

    it "postgres pg_log compression" do
      expect(shell("crontab -l | grep gzip_pglog_cronjob").exit_code).to be_zero
    end

    it "postgres pg_log compression gzip" do
      expect(shell("crontab -l | grep \"gzip -9\"").exit_code).to be_zero
    end

    it "postgres purge pg_log" do
      expect(shell("crontab -l | grep purge_pglog_cronjob").exit_code).to be_zero
    end

    it "postgres purge pg_log delete" do
      expect(shell("crontab -l | grep delete").exit_code).to be_zero
    end

  end
end
