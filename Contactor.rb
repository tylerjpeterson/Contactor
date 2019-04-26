class Contactor < Formula
	desc "Manage contacts from the command line via the macOS Contacts framework."
	homepage "https://github.com/kettle/Contactor"
	url "https://github.com/kettle/Contactor/releases/download/1.2.7/Contactor-1.2.7.tar.gz"
	sha256 "460b8832dbd3688f127384e401a65883ef039775c8bab79fbe4f568e430e4062"
	version "1.2.7"

	depends_on "curl"

	bottle :unneeded

	def install
		bin.install "Contactor"
	end
end
