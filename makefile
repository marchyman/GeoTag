PROJECT = GeoTag

buildServer.json:	Build
	xcode-build-server config -scheme $(PROJECT) -project $(PROJECT).xcodeproj

Build:	$(PROJECT).xcodeproj/project.pbxproj
	xcodebuild -scheme $(PROJECT)

$(PROJECT).xcodeproj/project.pbxproj:	project.yml
	xcodegen -c

.PHONY: proj tags test testapp testGpxTrackLog clean

# force project file rebuild
proj:
	xcodegen

tags:
	/opt/homebrew/bin/ctags -R

test:
	xcodebuild -scheme GeoTag test > .test.out
	xcresultparser `sed -n '/xcresult/p' .test.out`

testapp:
	xcodebuild -scheme AppOnly test > .test.out
	xcresultparser `sed -n '/xcresult/p' .test.out`

testGpxTrackLog:
	xcodebuild -scheme GpxTrackLog test > .test.out
	xcresultparser `sed -n '/xcresult/p' .test.out`

# remove files created during the build process
# do **not** use the -d option to git clean without excluding .jj
clean:
	test -d $(PROJECT).xcodeproj && xcodebuild clean || true
	jj status
	git clean -dfx -e .jj -e notes -e .session
