COMMAND_PATH="/usr/local/bin/publish"

# target: install   - Build and install the "publish" command line tool. Default target.
install:
	swift build -c release
	install .build/release/publish-cli $(COMMAND_PATH)

# target: uninstall - Remove the "publish" command line tool.
uninstall:
	rm -f $(COMMAND_PATH)

# target: help      - Display callable targets.
help:
	@echo "Callable targets:"
	@egrep "^# target: " [Mm]akefile | sed -e "s/#[[:space:]]target:[[:space:]]/   /g"
