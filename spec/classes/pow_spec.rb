require 'spec_helper'

describe 'pow' do
  let(:boxenhome) { '/opt/boxen' }
  let(:boxenuser) { 'github_user' }
  let(:facts) do
    {
      :boxen_home => boxenhome,
      :boxen_user => boxenuser,
      :macosx_productversion => '10.10',
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

    should contain_service('dev.pow.powd').with({
      :ensure  => 'running',
      :require => 'Package[boxen/brews/pow]'
    })

    should contain_package('boxen/brews/pow').with({
      :provider => 'homebrew',
      :require => 'File[/Users/github_user/.powconfig]'
    })

    should contain_file('/Users/github_user/.pow').with({
      :ensure => 'link',
      :target => '/opt/boxen/data/pow/hosts',
      :require => 'File[/opt/boxen/data/pow/hosts]'
    })

    should contain_file('/opt/boxen/data/pow/hosts').with_ensure('directory')
    should contain_file('/opt/boxen/log/pow').with_ensure('directory')
  end

  context 'when default parameters' do
    it do
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_HOST_ROOT=\/opt\/boxen\/data\/pow\/hosts/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_LOG_ROOT=\/opt\/boxen\/log\/pow/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_HTTP_PORT=30559/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DNS_PORT=30560/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DST_PORT=1999/)
      should contain_file("/Users/github_user/.powconfig").with_content(/^export POW_DOMAINS=pow/)
      should contain_file("/Users/github_user/.powconfig").without_content(/^export POW_EXT_DOMAINS=/)
      should contain_file("/Users/github_user/.powconfig").without_content(/^export POW_TIMEOUT=/)
      should contain_file("/Users/github_user/.powconfig").without_content(/^export POW_WORKERS=/)
    end
  end

  context 'when custom parameters' do
    let(:facts) do
      {
        :boxen_home => boxenhome,
        :boxen_user => boxenuser
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
        :ext_domains => 'test3, test4',
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

    context 'and custom log and host params' do
      let(:facts) do
        {
          :boxen_home => boxenhome,
          :boxen_user => boxenuser
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
  end

  context 'when nginx proxy enabled' do
    it do
      should contain_class('nginx::config')
      should contain_class('nginx')

      should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/server_name \*.pow;/)
      should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/proxy_pass http:\/\/localhost:30559;/)
    end

    context 'and custom http port is used' do
      let(:params) do
        {
          :http_port => 67895
        }
      end

      it do
        should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/proxy_pass http:\/\/localhost:67895;/)
      end
    end

    context 'and custom domains are used' do
      let(:params) do
        {
          :domains => 'dev,pow,test'
        }
      end

      it do
      should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/server_name \*.dev \*.pow \*.test;/)
      end
    end

    context 'and a missing custom nginx template is specified' do
      let(:params) do
        {
          :nginx_proxy => 'something/that/does/not/exist/pow.conf.erb'
        }
      end

      it do
        expect {
          should contain_file("/opt/boxen/config/nginx/sites/pow.conf")
        }.to raise_error(Puppet::Error, /could not find template/i)
      end
    end

    context 'and a custom nginx template is specified' do
      let(:params) do
        {
          :nginx_proxy => 'pow/nginx/custom/example.pow.conf.erb'
        }
      end

      it do
        should contain_file("/opt/boxen/config/nginx/sites/pow.conf").with_content(/proxy_set_header X-Custom-Header/)
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
      should_not contain_class('nginx::config')
      should_not contain_class('nginx')

      should_not contain_file("/opt/boxen/config/nginx/sites/pow.conf")

      should contain_file('/Library/LaunchDaemons/dev.pow.firewall.plist').with({
        :group  => 'wheel',
        :notify => 'Service[dev.pow.firewall]',
        :owner  => 'root'
      })

      should contain_service('dev.pow.firewall').with({
        :ensure  => 'running',
        :require => 'Package[boxen/brews/pow]'
      })
    end
  end

  context 'when using the default domain' do
    context 'with the default dns port' do
      it do
        should contain_file('/etc/resolver/pow').with({
          :group  => 'wheel',
          :owner  => 'root',
          :require  => 'File[/etc/resolver]'
        })
      end
    end

    context 'with a custom dns port' do
      let(:params) do
        {
          :dns_port => 45678
        }
      end

      it do
        should contain_file('/etc/resolver/pow').with({
          :group  => 'wheel',
          :owner  => 'root',
          :require  => 'File[/etc/resolver]'
        }).with_content(/^port 45678/)
      end
    end
  end

  context 'when using multiple custom multiple domains' do
    context 'with the default dns port' do
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

    context 'with a custom dns port' do
      let(:params) do
        {
          :dns_port => 45678,
          :domains => 'dev,pow, local'
        }
      end

      it do
        should contain_file('/etc/resolver/dev', '/etc/resolver/pow', '/etc/resolver/local').with({
          :group  => 'wheel',
          :owner  => 'root',
          :require  => 'File[/etc/resolver]'
        }).with_content(/^port 45678/)
      end
    end
  end
end
