install:
	swift build -c release
	sudo install .build/release/publish-cli /usr/local/bin/publish
