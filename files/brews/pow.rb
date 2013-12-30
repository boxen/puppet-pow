require 'formula'

class Pow < Formula
  homepage 'http://pow.cx/'
  url 'http://get.pow.cx/versions/0.4.1.tar.gz'
  sha1 '46976c6eea914ec78ba424b919e8928e4fc9a6bf'
  version '0.4.1-boxen1'

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
