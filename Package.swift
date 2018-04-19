// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "Contactor",
	products: [
		.library(
			name: "ContactorCore",
			targets: ["ContactorCore"]
		),
		.executable(
			name: "Contactor",
			targets: ["Contactor"]
		)
	],
	dependencies: [
		.package(
			url: "https://github.com/jakeheis/SwiftCLI",
			from: "5.0.0"
		)
	],
	targets: [
		.target(
			name: "Contactor",
			dependencies: [
				"SwiftCLI",
				"ContactorCore"
			]
		),
		.target(
			name: "ContactorCore"
		)
	],
	swiftLanguageVersions: [4]
)
