MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
TODAY := $(shell date +%Y%m%d)
TODAY_TAG := $(shell date +"%Y.%-m.%-d")

all:
	$(MAKE) init
	$(MAKE) create

push:
	git add -A
	git commit -m "add"
	git push

release:
	git tag -a v$(TODAY_TAG) -m "release $(TODAY_TAG)"
	git push origin v$(TODAY_TAG)

init:
	echo "BASEDIR=$(PWD)" > .env

create:
	mkdir $(TODAY)
	echo "# $(TODAY)\n" > $(TODAY)/README.md
	touch $(TODAY)/.gitignore

.PHONY: all push init create release
