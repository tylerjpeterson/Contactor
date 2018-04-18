class Contactor < Formula
	desc "Manage contacts from the command line via the macOS Contacts framework."
	homepage "https://github.com/kettle/Contactor"
	url "https://github.com/kettle/Contactor/releases/download/🥦/Contactor-🥦.tar.gz"
	sha256 "😇"
	version "🥦"

	depends_on "curl"

	bottle :unneeded

	def install
		bin.install "Contactor"
	end
end
