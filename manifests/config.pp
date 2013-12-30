# Public: Variables for working with Pow
#
# Examples
#
#   include pow::config
class pow::config {
  require boxen::config

  $dst_port   = 1999
  $http_port  = 30559
  $dns_port   = 30560
  $host_dir   = "${boxen::config::datadir}/pow/hosts"
  $log_dir    = "${boxen::config::logdir}/pow"
  $domains    = 'pow'
}
