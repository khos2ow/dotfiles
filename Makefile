.PHONY: gather
gather:
	cp $(HOME)/.gitconfig .

	cp -r /etc/apt/sources.list.d .

	git clone git@github.com:nojhan/liquidprompt.git $(HOME)/.liquidprompt
	cp -r $(HOME)/.config/liquidprompt .config
	cp $(HOME)/.config/liquidpromptrc .config

	cp -r $(HOME)/.themes .

test:
	echo "$(CURDIR)"
