require 'spec_helper'

describe 'pow' do
  let(:facts) do
    {
      :boxen_home => '/opt/boxen',
      :boxen_user => 'github_user'
    }
  end

  it do
    should contain_class('pow')

    should contain_file('/Library/LaunchAgents/dev.pow.powd.plist').with({
      :notify => 'Service[dev.pow.powd]'
    })

    should contain_file("/Users/github_user/.powconfig").with({
      :ensure => 'present',
      :mode => '0644'
      })
  end

  context 'when default parameters' do
    it do
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_HOST_ROOT=\/opt\/boxen\/data\/pow\/hosts/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_LOG_ROOT=\/opt\/boxen\/log\/pow/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_HTTP_PORT=30559/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DNS_PORT=30560/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DST_PORT=1999/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DOMAINS=pow/)
      should_not contain_file("/Users/github_user/.powconfig").with_content(/^export POW_EXT_DOMAINS=/)
      should_not contain_file("/Users/github_user/.powconfig").with_content(/^export POW_TIMEOUT=/)
      should_not contain_file("/Users/github_user/.powconfig").with_content(/^export POW_WORKERS=/)
    end
  end

  context 'when custom parameters' do
    let(:facts) do
      {
        :boxen_home => '/opt/boxen',
        :boxen_user => 'github_user'
      }
    end

    let(:params) do
      {
        :host_dir => '/test/data/pow/hosts',
        :log_dir => '/test/log/pow',
        :http_port => 76543,
        :dns_port => 45678,
        :dst_port => 23456,
        :domains => 'test,test2',
        :ext_domains => 'test3,test4',
        :timeout => 500,
        :workers => 4
      }
    end

    it do
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_HOST_ROOT=\/test\/data\/pow\/hosts/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_LOG_ROOT=\/test\/log\/pow/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_HTTP_PORT=76543/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DNS_PORT=45678/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DST_PORT=23456/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DOMAINS=test,test2/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_EXT_DOMAINS=test3,test4/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_TIMEOUT=500/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_WORKERS=4/)
    end
  end

  it do
    should contain_package('pow').with({
      :provider => 'homebrew',
      :ensure => 'latest',
      :require => 'File[/Users/github_user/.powconfig]'
    })
  end

  it do
    should contain_file('/Users/github_user/.pow').with({
      :ensure => 'link',
      :target => '/opt/boxen/data/pow/hosts',
      :require => 'File[/opt/boxen/data/pow/hosts]'
    })
    should contain_file('/opt/boxen/data/pow/hosts').with_ensure('directory')
    should contain_file('/opt/boxen/log/pow').with_ensure('directory')
  end

  context 'when custom parameters' do
    let(:facts) do
      {
        :boxen_home => '/opt/boxen',
        :boxen_user => 'github_user'
      }
    end

    let(:params) do
      {
        :host_dir => '/test/data/pow/hosts',
        :log_dir => '/test/log/pow'
      }
    end

    it do
      should contain_file("/Users/github_user/.pow").with({
        :ensure => 'link',
        :target => '/test/data/pow/hosts',
        :require => 'File[/test/data/pow/hosts]'
      })
      should contain_file('/test/data/pow/hosts').with_ensure('directory')
      should contain_file('/test/log/pow').with_ensure('directory')
    end
  end

  context 'when nginx proxy enabled' do
    it do
      should include_class('nginx::config')
      should include_class('nginx')

      should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/server_name \*.pow;/)
      should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/proxy_pass http:\/\/localhost:30559;/)
    end

    context 'when custom http port is used' do
      let(:params) do
        {
          :http_port => 67895
        }
      end

      it do
        should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/proxy_pass http:\/\/localhost:67895;/)
      end
    end

    context 'when custom domains are used' do
      let(:params) do
        {
          :domains => 'dev,pow,test'
        }
      end

      it do
      should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/server_name \*.dev \*.pow \*.test;/)
      end
    end
  end

  context 'when nginx proxy disabled' do
    let(:params) do
      {
        :nginx_proxy => false
      }
    end

    it do
      should_not include_class('nginx::config')
      should_not include_class('nginx')

      should_not contain_file("/opt/boxen/config/nginx/sites/pow.conf")

      should contain_file('/Library/LaunchDaemons/dev.pow.firewall.plist').with({
        :group  => 'wheel',
        :notify => 'Service[dev.pow.firewall]',
        :owner  => 'root'
      })

      should contain_service('dev.pow.firewall').with({
        :ensure  => 'running',
        :require => 'Package[pow]'
      })
    end
  end

  it do
    should contain_service('dev.pow.powd').with({
      :ensure  => 'running',
      :require => 'Package[pow]'
    })
  end

  context 'when default domain' do
    it do
      should contain_file('/etc/resolver/pow').with({
        :group  => 'wheel',
        :owner  => 'root',
        :require  => 'File[/etc/resolver]'
      })
    end
  end

  context 'when multiple domains' do
    let(:params) do
      {
        :domains => 'dev,pow, local'
      }
    end

    it do
      should contain_file('/etc/resolver/dev', '/etc/resolver/pow', '/etc/resolver/local').with({
        :group  => 'wheel',
        :owner  => 'root',
        :require  => 'File[/etc/resolver]'
      })
    end
  end
end
