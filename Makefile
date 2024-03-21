SHELL=/bin/bash
PHONY=default start-next-version

.PHONY: $(PHONY)

default: start-next-version

start-next-version:
	./app/start_next_version.sh $(VERSION)

reset-next-version:
	./app/reset_next_version.sh $(VERSION)

