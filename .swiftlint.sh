if [[ "$(uname -m)" == arm64 ]]; then
    # Xcode has its own idea of the path and it does not include /opt/homebrew
    export PATH="/opt/homebrew/bin:$PATH"
fi
if which swiftlint > /dev/null; then
    swiftlint
else
    echo 'warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint or install using brew'
fi
