class Touchglass < Formula
  desc "Liquid Glass PIN and touch prompts for YubiKey operations in gpg-agent"
  homepage "https://github.com/ambroos/touchglass"
  url "https://github.com/ambroos/touchglass/archive/refs/tags/v0.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "Apache-2.0"
  head "https://github.com/ambroos/touchglass.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "gnupg"
  depends_on macos: :tahoe
  depends_on "pinentry-mac"

  uses_from_macos "swift" => :build

  deny_network_access!

  def install
    # On macOS, std_swift_args includes --disable-sandbox: SwiftPM's sandbox
    # cannot nest inside Homebrew's build sandbox.
    %w[TouchGlass touchglass-pinentry touchglass-scdaemon].each do |product|
      system "swift", "build", "--product", product, *std_swift_args
    end
    ENV["TOUCHGLASS_VERSION"] = version.to_s
    system "scripts/build-app.sh", "--prebuilt", ".build/release"
    prefix.install "build/TouchGlass.app"
    # The CLI finds the bundle it lives in, so run it there instead of copying it.
    bin.write_exec_script prefix/"TouchGlass.app/Contents/Resources/touchglass"
  end

  def caveats
    <<~EOS
      To connect TouchGlass to gpg-agent, run:
        touchglass install
      It prints the gpg-agent.conf changes to make and how to restart
      gpg-agent. To have it edit gpg-agent.conf for you instead, run:
        touchglass install --apply

      Upgrades need no new install. The host switches to the new version
      after its next PIN prompt; to switch it and scdaemon now, run:
        pkill -x TouchGlass
        gpgconf --kill scdaemon

      Before `brew uninstall touchglass`, run `touchglass uninstall` for
      how to restore gpg-agent.conf. `brew uninstall` can also remove
      pinentry-mac if nothing else needs it.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/touchglass --version")

    ENV["GNUPGHOME"] = testpath/"gnupg"
    assert_match "doesn't use TouchGlass", shell_output("#{bin}/touchglass status")

    # Without a host or a fallback pinentry, the pinentry answers by itself and shows nothing.
    ENV["TOUCHGLASS_HOST_APP"] = "none"
    ENV["TOUCHGLASS_SOCKET"] = testpath/"host.sock"
    ENV["TOUCHGLASS_FALLBACK_PINENTRY"] = testpath/"no-fallback"
    pinentry = prefix/"TouchGlass.app/Contents/MacOS/touchglass-pinentry"
    # A --HEAD build reports HEAD-<commit>, which the version in this test may not include.
    expected = version.head? ? /^D HEAD-\h+$/ : /^D #{Regexp.escape(version.to_s)}$/
    assert_match expected, pipe_output(pinentry, "GETINFO version\nBYE\n", 0)
  end
end
