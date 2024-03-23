SHELL=/bin/bash
PHONY=default start-feature-version merge-feature-version-step1 merge-feature-version-step2-after-merge reset-feature-version help

.PHONY: $(PHONY)

default: help

start-feature-version:
	./app/start_feature_version.sh $(VERSION)

merge-feature-version-step1:
	./app/merge_feature_version_step1.sh $(VERSION)

merge-feature-version-step2-after-merge:
	./app/merge_feature_version_step2_after_merge.sh

reset-feature-version:
	./app/reset_feature_version.sh $(VERSION)

help:
	@echo "Usage: "
	@echo "	make start-feature-version"
	@echo "	make merge-feature-version-step1"
	@echo "	make merge-feature-version-step2-after-merge"
	@echo "	make reset-feature-version"

