# Build from the command line

all:
	xcodebuild -configuration Release -alltargets
	mv build/Release/*.dmg ~/Desktop

clean:
	xcodebuild -configuration Release -alltargets clean
	xcodebuild -configuration Debug -alltargets clean
