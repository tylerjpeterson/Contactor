#!/usr/bin/env bash

gem install xcodeproj && \
	swift package generate-xcodeproj && \
	ruby "bin/config.rb" "Contactor.xcodeproj/"
