Pod::Spec.new do |s|
	s.name = "Contactor"
	s.version = "1.0.1"
	s.summary = "Manage contacts via the macOS Contacts framework."
	s.homepage = "https://github.com/kettle/Contactor"
	s.license = { :type => "MIT" }
	s.authors = { "tylerjpeterson" => "tylerjpeterson@gmail.com" }

	s.requires_arc = true
	s.osx.deployment_target = "10.11"
	s.source = { :git => "https://github.com/kettle/Contactor.git", :tag => s.version }
	s.source_files = "Sources/ContactorCore/*.swift", "Sources/Contactor/*.swift"
end
