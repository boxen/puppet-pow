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
    file { "/Library/LaunchAgents/dev.pow.powd.plist":
      content => template('pow/dev.pow.powd.plist.erb'),
      notify  => Service['dev.pow.powd'],
      group   => 'wheel',
      owner   => 'root'
    }

    # Install pow with brew
    package { 'pow':
      ensure   => 'latest',
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

        # Create the site with a proxy from port 80 to $http_port
        file { "${nginx::config::sitesdir}/pow.conf":
            content => template('pow/nginx/pow.conf.erb'),
            require => File[$nginx::config::sitesdir],
            notify  => Service['dev.nginx'],
        }
    }
    # Create a firewall rule to redirect from $dst_port to $http_port
    else{
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
        require => Package['pow']
      }
    }

    # Start the pow service
    service { 'dev.pow.powd':
      ensure  => running,
      require => Package['pow']
    }

    # Add the dns resolver for each domain
    $pow_domains = split(strip($domains), ',')
    $pow_domain_resolvers = prefix($pow_domains, '/etc/resolver/')

    file { $pow_domain_resolvers:
      content => template('pow/resolver.erb'),
      group   => 'wheel',
      owner   => 'root',
      require => File['/etc/resolver']
    }
}
