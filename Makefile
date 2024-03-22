SHELL=/bin/bash
PHONY=default start-next-version merge-feature-version reset-next-version help

.PHONY: $(PHONY)

default: help

start-next-version:
	./app/start_next_version.sh $(VERSION)

merge-feature-version:
	./app/merge_feature_version.sh $(VERSION)

complete-merge:
	./app/complete_merge.sh

reset-next-version:
	./app/reset_next_version.sh $(VERSION)

help:
	@echo "Usage: "
	@echo "	make start-next-version"
	@echo "	make merge-feature-version"
	@echo "	make complete-merge"
	@echo "	make reset-next-version"

