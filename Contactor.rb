class Contactor < Formula
	desc "Manage contacts from the command line via the macOS Contacts framework."
	homepage "https://github.com/kettle/Contactor"
	url "https://github.com/kettle/Contactor/releases/download/1.2.2/Contactor-1.2.2.tar.gz"
	sha256 "4eff5c04cad0f6e88f9b080bfe705d52137b19c8390c922ade3bc5498ee252a3"
	version "1.2.2"

	depends_on "curl"

	bottle :unneeded

	def install
		bin.install "Contactor"
	end
end
