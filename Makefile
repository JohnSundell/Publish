install:
	swift build -c release
	install .build/release/publish-cli /usr/local/bin/publish
