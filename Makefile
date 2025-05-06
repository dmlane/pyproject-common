## Config
MAKEFLAGS += --no-builtin-rules
export PROJECT_NAME := $(shell poetry version|cut -d" " -f1)
PYTHON_FILES :=  $(shell find src/ tests/ -type f -name '*.py')
export HELPER:=.common/bin
export SRC_DIRS := src/$(subst dml-,,$(PROJECT_NAME))
export WORK_DIR := ${HOME}/.cache/dml.poetry/$(PROJECT_NAME)
POETRY := $(shell command -v poetry 2> /dev/null)
PYENV := $(shell command -v pyenv 2> /dev/null)
-include $(WORK_DIR)/.versions

# Flags used by helpers
export BUMPVER_FLAG := $(WORK_DIR)/bumpver_versions.flg

ifdef TERM
BOLD_COLOR := $(shell tput setaf 3)
HELP_COLOR := $(shell tput setaf 6)
HEADER_COLOR := $(BOLD_COLOR)$(shell tput setaf 2)
NO_COLOR := $(shell tput sgr0)
endif
define DISPLAY
    @printf "Setting up $(BOLD_COLOR)$@$(NO_COLOR) ...........\n"
endef
#------------------------------------------------------
$(WORK_DIR)/%.rel: $(WORK_DIR)/%.bumpver
	@touch $@

$(WORK_DIR)/%.bumpver: Makefile pyproject.toml $(WORK_DIR)/$(PROJECT_NAME).tmpl $(PYTHON_FILES)
	$(DISPLAY)
	$(BUMPVER)
	@touch $@

#------------------------------------------------------
rc: BUMPVER = bumpver update -t rc --tag-num
rc: $(WORK_DIR)/rc.rel

help:  ## List all commands
	@printf "\n$(BOLD_COLOR)***** $(PROJECT_NAME) Makefile help *****$(NO_COLOR)\n"
	@# This code borrowed from https://github.com/jedie/poetry-publish/blob/master/Makefile
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9 -]+:.*?## / {printf "$(HELP_COLOR)%-20s$(NO_COLOR) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@printf "$(BOLD_COLOR)Options:$(NO_COLOR)\n"
	@printf "$(HELP_COLOR)%-20s$(NO_COLOR) %s\n" rc "Build and deploy a release-candidate file (DEFAULT)"
	@printf "$(HELP_COLOR)%-20s$(NO_COLOR) %s\n" release "Build and deploy a release file"
	@printf "$(HELP_COLOR)%-20s$(NO_COLOR) %s\n" test "Run pytest"
	@printf "$(HELP_COLOR)%-20s$(NO_COLOR) %s\n" check  "Run pylint against all python files"
	@printf "$(HELP_COLOR)%-20s$(NO_COLOR) %s\n" clean "Cleanup environment and remove python venv"
	@printf "$(HELP_COLOR)%-20s$(NO_COLOR) %s\n" setup "Create a clean virtualenv and setup"
	@echo ""
setup: $(WORK_DIR)/setup.flg

test:
	pytest

release: BUMPVER = bumpver update -t final
release: $(WORK_DIR)/release.rel
	

$(WORK_DIR)/setup.flg:
	@printf "$(BOLD_COLOR)Setting up environment ----------$(NO_COLOR)\n"
	@$(HELPER)/mk_setup_environment.sh
	@touch $@
	@printf "$(BOLD_COLOR)SETUP finished ++++++++++$(NO_COLOR)\n"

.PHONY: clean
clean:
	@printf "$(BOLD_COLOR)Cleaning environment -----------$(NO_COLOR)\n"
	@$(HELPER)/mk_setup_environment.sh -d
	@printf "$(BOLD_COLOR)CLEAN finished  +++++++++++$(NO_COLOR)\n"

.PHONY: check
check:
	@pylint $(PYTHON_FILES)

$(WORK_DIR)/$(PROJECT_NAME).tmpl: poetry.lock
	$(DISPLAY)

# Generate include file
.PRECIOUS: $(WORK_DIR)/.versions
$(WORK_DIR)/.versions: pyproject.toml
	bumpver  update  -t final -d 2>&1 >/dev/null |sed -n 's/^.*New Version: /RELEASE_VERSION=/p'   >$@
	bumpver  update -t rc --tag-num -d 2>&1 >/dev/null |sed -n 's/^.*New Version: /RC_VERSION=/p' >>$@
	@$(POETRY) version -s|sed 's/^/VERSION=/' >>$@

# Not normally called
.PHONY: vars
vars:
	@echo "export VERSION  .......... '$(VERSION)'"
	@echo "export RC_VERSION ........ '$(RC_VERSION)'"
	@echo "export RELEASE_VERSION ... '$(RELEASE_VERSION)'"

