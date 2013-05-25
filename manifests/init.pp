# Installs Pow using HomeBrew
#
# Usage:
#
#     include pow
class pow {
  package { 'pow':
    ensure   => 'latest',
    provider => 'homebrew'
  }
}
