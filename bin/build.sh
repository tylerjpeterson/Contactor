#!/usr/bin/env bash

PROD=$1

CONF="debug"
DIR="Debug"

swift package update && \
	swift package clean

if [ "$PROD" ]; then
	CONF="release"
	DIR="Release"
fi

rm -rf ".build/$CONF/"

swift build \
	-c "$CONF" \
	--product "Contactor" \
	-Xswiftc "-target" \
	-Xswiftc "x86_64-apple-macosx10.13" \
	--no-static-swift-stdlib

cp -f ".build/$CONF/Contactor" "/usr/local/bin/Contactor"
