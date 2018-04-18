#!/usr/bin/env bash

VER=$1
source "bin/build.sh"

cp "/usr/local/bin/Contactor" "releases/"

tar -czf "releases/Contactor-$VER.tar.gz" "releases/Contactor"

rm "releases/Contactor"

SHA="$(shasum -a 256 "releases/Contactor-$VER.tar.gz" | awk '{printf $1}')"

cp "bin/release.template.rb" "Contactor.rb"
cp "bin/Info.template.plist" "Info.plist"

sed -i "" s,🥦,$VER,g "Info.plist"
sed -i "" s,🥦,$VER,g "Contactor.rb"
sed -i "" s,😇,$SHA,g "Contactor.rb"

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
