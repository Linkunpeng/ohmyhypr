REPO := $(abspath .)

.PHONY: verify dev shell doctor ctx install-cli avatar-run themes

verify:        ## static checks: Lua config, Python, adapter protocol, themes
	@scripts/verify.sh

dev:           ## nested Hyprland running this repo's config
	@scripts/dev-nested.sh

shell:         ## run the Quickshell UI on the current desktop
	qs -p $(REPO)/shell

doctor:        ## check dependencies and services
	@bin/omh doctor

ctx:           ## print current desktop context
	@bin/omh ctx --no-clipboard

install-cli:   ## put `omh` on PATH (editable)
	uv tool install --editable ./brain

avatar-run:    ## start the avatar on the current desktop
	@bin/omh avatar run --detach

themes:        ## list themes
	@bin/omh theme list
