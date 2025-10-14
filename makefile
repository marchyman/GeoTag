PROJECT = GeoTag

buildServer.json:	Build
	xcode-build-server config -scheme "$(PROJECT)" -project $(PROJECT).xcodeproj

Build:	$(PROJECT).xcodeproj/project.pbxproj
	xcodebuild -scheme $(PROJECT)

$(PROJECT).xcodeproj/project.pbxproj:	project.yml
	xcodegen -c

# force project file rebuild
proj:
	xcodegen

test:
	xcodebuild -scheme GeoTag test | tee .test.out | xcbeautify

testGpxTrackLog:
	xcodebuild -scheme GpxTrackLog test | tee .test.out | xcbeautify

# remove files created during the build process
# do **not** use the -d option to git clean without excluding .jj
clean:
	xcodebuild clean
	jj status
	git clean -dfx -e .jj -e notes
