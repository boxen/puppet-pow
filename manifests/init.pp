# Installs Pow using HomeBrew
#
# Usage:
#
#     include pow
class pow(
  $host_dir = $pow::config::host_dir,
  $log_dir = $pow::config::log_dir,
  $dns_port = $pow::config::dns_port,
  $http_port = $pow::config::http_port,
  $dst_port = $pow::config::dst_port,
  $domains = $pow::config::domains,
  $ext_domains = undef,
  $timeout = undef,
  $workers = undef,
  $nginx_proxy = true,

) inherits pow::config {
    include boxen::config
    include homebrew::config

    # Current user
    $current_user = $::boxen_user

    # Pow root
    $pow_dir = regsubst($host_dir, '\/hosts$', '')

    # Pow executable
    $pow_bin = "${homebrew::config::installdir}/bin/pow"

    $pow_domains = strip(split($domains, ','))
    $pow_ext_domains = strip(split($ext_domains, ','))
    $all_pow_domains = union($pow_domains, $pow_ext_domains)

    $home = "/Users/${::boxen_user}"
    file { "${home}/.powconfig":
      ensure  => present,
      content => template('pow/powconfig.erb'),
      mode    => '0644'
    }

    # Install our custom plist for pow.
    # NOTE: Puppet launchd service provider cannot manage
    # per-user setted by user in ~/Library/LaunchAgents
    # We will set the pow daemon in the per-user set by
    # administrator location
    file { '/Library/LaunchAgents/dev.pow.powd.plist':
      content => template('pow/dev.pow.powd.plist.erb'),
      notify  => Service['dev.pow.powd'],
      group   => 'wheel',
      owner   => 'root'
    }

    # Install pow with brew
    homebrew::formula { 'pow':
      before => Package['boxen/brews/pow'],
    }

    package { 'boxen/brews/pow':
      ensure   => '0.5.0-boxen1',
      provider => 'homebrew',
      require  => File["${home}/.powconfig"]
    }

    # Create the required host directories:
    file { [
        $pow_dir,
        $host_dir,
        $log_dir
        ]:
        ensure => directory
    }

    # Create the symbolic link to hosts
    file { "${home}/.pow":
        ensure  => link,
        target  => $host_dir,
        require => File[$host_dir],
    }

    # Use the nginx proxy on port 80
    if $nginx_proxy {
        include nginx::config
        include nginx

        $nginx_templ = $nginx_proxy ? {
          true    => 'pow/nginx/pow.conf.erb',
          default => $nginx_proxy,
        }

        $all_pow_wildcard_domains = prefix($all_pow_domains, '*.')
        # Create the site with a proxy from port 80 to $http_port
        file { "${nginx::config::sitesdir}/pow.conf":
            content => template($nginx_templ),
            require => File[$nginx::config::sitesdir],
            notify  => Service['dev.nginx'],
        }
    }
    # Create a firewall rule to redirect from $dst_port to $http_port
    else{
      $firewall_update_cmd =  $::macosx_productversion ? {
        '10.10'         => "echo 'rdr pass proto tcp from any to any port {${dst_port},${http_port}} -> 127.0.0.1 port ${http_port}' | pfctl -a 'com.apple/250.PowFirewall' -Ef -",
        /10\.[7-9]/     => "ipfw add fwd 127.0.0.1,${http_port} tcp from any to me dst-port ${dst_port} in",
      }

      # Install our custom plist for pow firewall.
      file { '/Library/LaunchDaemons/dev.pow.firewall.plist':
        content => template('pow/dev.pow.firewall.plist.erb'),
        group   => 'wheel',
        notify  => Service['dev.pow.firewall'],
        owner   => 'root'
      }

      # Start the pow firewall service
      service { 'dev.pow.firewall':
        ensure  => running,
        require => Package['boxen/brews/pow']
      }
    }

    # Start the pow service
    service { 'dev.pow.powd':
      ensure  => running,
      require => Package['boxen/brews/pow']
    }

    # Add the dns resolver for each domain
    $pow_domain_resolvers = prefix($pow_domains, '/etc/resolver/')

    file { $pow_domain_resolvers:
      content => template('pow/resolver.erb'),
      group   => 'wheel',
      owner   => 'root',
      require => File['/etc/resolver']
    }
}
