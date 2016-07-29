require 'formula'

class ErlangManuals < Formula
  url 'http://erlang.org/download/otp_doc_man_R16B01.tar.gz'
  sha1 '57ef01620386108db83ef13921313e600d351d44'
end

class ErlangHtmls < Formula
  url 'http://erlang.org/download/otp_doc_html_R16B01.tar.gz'
  sha1 '6741e15e0b3e58736987e38fb8803084078ff99f'
end

class ErlangHeadManuals < Formula
  url 'http://erlang.org/download/otp_doc_man_R16B01.tar.gz'
  sha1 '57ef01620386108db83ef13921313e600d351d44'
end

class ErlangHeadHtmls < Formula
  url 'http://erlang.org/download/otp_doc_html_R16B01.tar.gz'
  sha1 '6741e15e0b3e58736987e38fb8803084078ff99f'
end

class Erlang < Formula
  homepage 'http://www.erlang.org'
  # Download tarball from GitHub; it is served faster than the official tarball.
  url 'https://github.com/erlang/otp/archive/OTP_R16B01.tar.gz'
  sha1 'ddbff080ee39c50b86b847514c641f0a9aab0333'


  head 'https://github.com/erlang/otp.git', :branch => 'dev'

  bottle do
  end

  # remove the autoreconf if possible
  depends_on :automake
  depends_on :autoconf
  depends_on :libtool
  depends_on 'openssl' if build.with? 'openssl'

  fails_with :llvm do
    build 2334
  end

  option 'disable-hipe', 'Disable building hipe; fails on various OS X systems'
  option 'halfword', 'Enable halfword emulator (64-bit builds only)'
  option 'time', '`brew test --time` to include a time-consuming test'
  option 'no-docs', 'Do not install documentation'
  option 'with-openssl', 'Use brewed OpenSSL instead of OS X provided one'

  def install
    ohai "Compilation takes a long time; use `brew install -v erlang` to see progress" unless ARGV.verbose?

    if ENV.compiler == :llvm
      # Don't use optimizations. Fixes build on Lion/Xcode 4.2
      ENV.remove_from_cflags /-O./
      ENV.append_to_cflags '-O0'
    end

    # Do this if building from a checkout to generate configure
    system "./otp_build autoconf" if File.exist? "otp_build"

    args = ["--disable-debug",
            "--prefix=#{prefix}",
            "--enable-kernel-poll",
            "--enable-threads",
            "--enable-shared-zlib",
            "--enable-smp-support"]

    if build.with? 'openssl'
          args << "--disable-dynamic-ssl-lib"
          args << "--with-ssl=#{Formula.factory("openssl").opt_prefix}"
    else
      args << "--enable-dynamic-ssl-lib"
    end

    args << "--with-dynamic-trace=dtrace" unless MacOS.version == :leopard or not MacOS::CLT.installed?

    unless build.include? 'disable-hipe'
      # HIPE doesn't strike me as that reliable on OS X
      # http://syntatic.wordpress.com/2008/06/12/macports-erlang-bus-error-due-to-mac-os-x-1053-update/
      # http://www.erlang.org/pipermail/erlang-patches/2008-September/000293.html
      args << '--enable-hipe'
    end

    if MacOS.prefer_64_bit?
      args << "--enable-darwin-64bit"
      args << "--enable-halfword-emulator" if build.include? 'halfword' # Does not work with HIPE yet. Added for testing only
    end

    system "./configure", *args
    system "make"
    ENV.j1
    system "make install"

    unless build.include? 'no-docs'
      manuals = build.head? ? ErlangHeadManuals : ErlangManuals
      manuals.new.brew { man.install Dir['man/*'] }

      htmls = build.head? ? ErlangHeadHtmls : ErlangHtmls
      htmls.new.brew { doc.install Dir['*'] }
    end
  end

  def test
    `#{bin}/erl -noshell -eval 'crypto:start().' -s init stop`

    # This test takes some time to run, but per bug #120 should finish in
    # "less than 20 minutes". It takes a few minutes on a Mac Pro (2009).
    if build.include? "time"
      `#{bin}/dialyzer --build_plt -r #{lib}/erlang/lib/kernel-2.15/ebin/`
    end
  end
end
