.PHONY: all
all: bin dotfiles ## Installs the bin and etc directory files and the dotfiles.

.PHONY: bin
bin: ## Installs the bin directory files.
	# add aliases for things in bin
	for file in $(shell find $(CURDIR)/bin -type f -not -name "*-backlight" -not -name ".*.swp"); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/bin/$$f; \
	done

.PHONY: dotfiles
dotfiles: ## Installs the dotfiles.
	# add aliases for dotfiles
	@ for file in $(shell find $(CURDIR) -maxdepth 1 -not -path "$(CURDIR)" -name ".*" -not -name ".gitignore" -not -name ".travis.yml" -not -name ".git" -not -name ".*.swp" -not -name ".gnupg" -not -name ".config" -not -name ".github"); do \
		f=$$(basename $$file); \
		ln -snf $$file $(HOME)/$$f; \
		echo ln -snf $$file $(HOME)/$$f; \
	done

	ln -snf $(CURDIR)/.bash_profile $(HOME)/.profile
	ln -snf $(CURDIR)/gitignore $(HOME)/.gitignore

	mkdir -p $(HOME)/.local/share
	ln -snf $(CURDIR)/.fonts $(HOME)/.local/share/fonts
	fc-cache -f -v || true

	mkdir -p $(HOME)/.config
	@ for file in $(shell find $(CURDIR)/.config -maxdepth 1 -not -path "$(CURDIR)/.config" -name "*" -not -name "fontconfig" -not -name "regolith"); do \
		f=$$(basename $$file); \
		echo "ln -snf $(CURDIR)/.config/$$f $(HOME)/.config/$$f" ; \
		ln -snf $(CURDIR)/.config/$$f $(HOME)/.config/$$f ; \
	done
	@ for dir in fontconfig regolith ; do \
		echo "mkdir -p $(HOME)/.config/$$dir" ; \
		mkdir -p $(HOME)/.config/$$dir ; \
		for file in $$(find "$(CURDIR)/.config/$$dir" -maxdepth 1 -not -path "$(CURDIR)/.config/$$dir"); do \
			f=$$(basename $$file); \
			echo "ln -snf $(CURDIR)/.config/$$dir/$$f $(HOME)/.config/$$dir/$$f" ; \
			ln -snf $(CURDIR)/.config/$$dir/$$f $(HOME)/.config/$$dir/$$f ; \
		done ; \
	done

	@ if [ ! -d $(HOME)/.liquidprompt ]; then \
		git clone https://github.com/nojhan/liquidprompt.git $(HOME)/.liquidprompt ; \
	fi

	sudo ln -snf $(CURDIR)/etc/bash_completion.d/kubie /etc/bash_completion.d/kubie

.PHONY: etc
etc: ## Installs the etc directory files.
	sudo mkdir -p /etc/docker/seccomp
	for file in $(shell find $(CURDIR)/etc -type f -not -name ".*.swp"); do \
		f=$$(echo $$file | sed -e 's|$(CURDIR)||'); \
		sudo mkdir -p $$(dirname $$f); \
		sudo ln -f $$file $$f; \
	done
	systemctl --user daemon-reload || true
	sudo systemctl daemon-reload
	sudo systemctl enable systemd-networkd systemd-resolved
	sudo systemctl start systemd-networkd systemd-resolved
	sudo ln -snf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

.PHONY: usr
usr: ## Installs the usr directory files.
	for file in $(shell find $(CURDIR)/usr -type f -not -name ".*.swp"); do \
		f=$$(echo $$file | sed -e 's|$(CURDIR)||'); \
		sudo mkdir -p $$(dirname $$f); \
		sudo ln -f $$file $$f; \
	done

.PHONY: test
test: shellcheck ## Runs all the tests on the files in the repository.

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif

.PHONY: shellcheck
shellcheck: ## Runs the shellcheck tests on the scripts.
	docker run --rm -i $(DOCKER_FLAGS) \
		--name df-shellcheck \
		-v $(CURDIR):/usr/src:ro \
		--workdir /usr/src \
		koalaman/shellcheck:stable .

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
