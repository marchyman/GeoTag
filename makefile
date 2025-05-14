PROJECT = GeoTag

buildServer.json:	Build
	xcode-build-server config -scheme "$(PROJECT)" -project $(PROJECT).xcodeproj
	sed -i '~' "/\"build_root\"/s/: \"\(.*\)\"/: \"\1\/DerivedData\/$(PROJECT)\"/" buildServer.json

Build:	$(PROJECT).xcodeproj/project.pbxproj
	xcodebuild -scheme $(PROJECT)

$(PROJECT).xcodeproj/project.pbxproj:	project.yml
	xcodegen -c

