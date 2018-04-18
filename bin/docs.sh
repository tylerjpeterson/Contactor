#!/usr/bin/env bash

rm -rf docs/

mkdir -p docs

# Install / upgrade swiftlint
if ! [ -x "$(command -v swiftlint)" ]; then
	brew install swiftlint
fi

# Lints the Swift code
swiftlint autocorrect

jazzy \
	--output "docs/Contactor" \
	--no-clean \
	--min-acl=private \
	--sdk=macosx \
	--readme "README.md" \
	--author "Tyler Peterson" \
	--module "Contactor" \
	--disable-search \
	--github_url "https://github.com/kettle/Contactor" \
	--swift-version 4.1 \
	--theme=fullwidth

jazzy \
	--output "docs/ContactorCore" \
	--no-clean \
	--min-acl=private \
	--sdk=macosx \
	--readme "CORE.md" \
	--author "Tyler Peterson" \
	--module "ContactorCore" \
	--github_url "https://github.com/kettle/Contactor" \
	--disable-search \
	--swift-version 4.1 \
	--theme=fullwidth
