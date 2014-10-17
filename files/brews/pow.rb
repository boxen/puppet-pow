require 'formula'

class Pow < Formula
  homepage 'http://pow.cx/'
  url "http://get.pow.cx/versions/0.5.0.tar.gz"
  sha1 "ef44f886a444340b91fb28e2fab3ce5471837a08"
  version '0.5.0-boxen1'

  depends_on 'node'

  def install
    libexec.install Dir['*']
    (bin/'pow').write <<-EOS.undent
      #!/bin/sh
      export POW_BIN="#{HOMEBREW_PREFIX}/bin/pow"
      exec "#{HOMEBREW_PREFIX}/bin/node" "#{libexec}/lib/command.js" "$@"
    EOS
  end

end
