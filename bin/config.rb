gem 'xcodeproj'
require 'xcodeproj'

project_file = "Contactor.xcodeproj/"

project = Xcodeproj::Project.open(project_file)

fixConfiguration = lambda do |configuration|
	configuration.build_settings.delete('SWIFT_FORCE_STATIC_LINK_STDLIB')
	configuration.build_settings['SWIFT_FORCE_DYNAMIC_LINK_STDLIB'] = 'YES'
	configuration.build_settings['MACOSX_DEPLOYMENT_TARGET'] = 10.13
	configuration.build_settings['SUPPORTED_PLATFORMS'] = ['macosx']
	configuration.build_settings['SWIFT_VERSION'] = 4.1

	if configuration.build_settings['OTHER_SWIFT_FLAGS'].kind_of?(Array)
		configuration.build_settings['OTHER_SWIFT_FLAGS'] = configuration.build_settings['OTHER_SWIFT_FLAGS'].map { |n| n.sub("x86_64-apple-macosx10.10", "x86_64-apple-macosx10.13") }
	else
		configuration.build_settings['OTHER_SWIFT_FLAGS'] = configuration.build_settings['OTHER_SWIFT_FLAGS'].sub("x86_64-apple-macosx10.10", "x86_64-apple-macosx10.13")
	end
end

project.build_configurations.each(&fixConfiguration)

project.targets.each { |target| target.build_configurations.each(&fixConfiguration) }

project.save
