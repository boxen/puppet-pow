# Puppet module for Pow

[![Build Status](https://travis-ci.org/boxen/puppet-pow.png)](https://travis-ci.org/boxen/puppet-pow)

Installs Pow, a simple app server from 37 Signals.

http://pow.cx

## Usage

``` puppet
include pow

# include with some custom params
# this example shows the default values
class {'pow':
      host_dir => '/opt/boxen/data/pow/hosts',
      log_dir => '/opt/boxen/logs/pow',
      dns_port => 30560,
      http_port => 30559,
      dst_port => 1999,
      domains => 'pow',
      ext_domains => undef,     # uses pow default, ""
      timeout => undef,         # uses pow default, 900
      workers => undef,         # uses pow default, 2
      nginx_proxy => true
    }
```

The pow module installs pow with a custom `destination port` and use `nginx` to proxy custom domains to pow, instead of a firewall rule. You can change this behaviour with the `nginx_proxy` parameter

It also use the `.pow` TLD that resolve to `127.0.0.0` to serve your pow projects

## Required Puppet Modules

* `boxen`
* `nginx`
* `homebrew`
* `stdlib`

## Development

Write code. Run `script/cibuild` to test it. Check the `script`
directory for other useful tools.
