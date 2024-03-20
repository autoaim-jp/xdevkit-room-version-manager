SHELL=/bin/bash
PHONY=default start-next-version

.PHONY: $(PHONY)

default: start-next-version

start-next-version:
	./app/bin/start_next_version.sh $(VERSION)

