#!/usr/bin/env bash

VER=$1

OLD=$(egrep -o "([0-9]{1,}\.)+[0-9]{1,}" "Sources/Contactor/main.swift")

sed -i "" s/version\:\ \"$OLD\"/version\:\ \"$VER\"/g "Sources/Contactor/main.swift"

source "bin/build.sh"

cp "/usr/local/bin/Contactor" "releases/"

tar -czf "releases/Contactor-$VER.tar.gz" "releases/Contactor"

rm "releases/Contactor"

SHA="$(shasum -a 256 "releases/Contactor-$VER.tar.gz" | awk '{printf $1}')"

cp "bin/release.template.rb" "Contactor.rb"
cp "bin/Info.template.plist" "Info.plist"
cp "bin/Contactor.template.podspec" "Contactor.podspec"

sed -i "" s,🥦,$VER,g "Info.plist"
sed -i "" s,🥦,$VER,g "Contactor.rb"
sed -i "" s,😇,$SHA,g "Contactor.rb"
sed -i "" s,🥦,$VER,g "Contactor.podspec"

mv "Contactor.rb" "../../Formulae/homebrew-kettle/Contactor.rb"

git add . && \
	git commit -m "Release $VER" && \
	git push origin master && \
	git tag -a $VER -m "Release $VER" && \
	git push origin master --tags

hub release create -a "releases/Contactor-$VER.tar.gz" -m "Release v$VER" -f "./releases/Contactor-$VER.tar.gz" $VER

git push origin master

cd "../../Formulae/homebrew-kettle"

git add . && git commit -m "Release $VER" && git push origin master
