SHELL=/bin/bash
PHONY=default start-feature-version merge-feature-version-step1 merge-feature-version-step2-after-merge reset-feature-version help

.PHONY: $(PHONY)

default: help

start-feature-version: validation
	./app/start_feature_version.sh $(VERSION)

merge-feature-version-step1: validation
	./app/merge_feature_version_step1.sh $(VERSION)

merge-feature-version-step2-after-merge:
	./app/merge_feature_version_step2_after_merge.sh

reset-feature-version: validation
	./app/reset_feature_version.sh $(VERSION)

help:
	@echo "Usage: "
	@echo "	make start-feature-version VERSION=<branch>"
	@echo "	make merge-feature-version-step1 VERSION=<branch>"
	@echo "	make merge-feature-version-step2-after-merge"
	@echo "	make reset-feature-version VERSION=<branch>"

ERROR_MSG := Invalid argument. 'make help' will help you
validation:
ifndef VERSION
	$(error $(ERROR_MSG))
endif


