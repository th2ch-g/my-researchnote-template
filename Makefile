MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
TODAY := $(shell date +%Y%m%d)

all:
	$(MAKE) init
	$(MAKE) create

push:
	git add -A
	git commit -m "add"
	git push

init:
	echo "BASEDIR=$(PWD)" > .env

create:
	mkdir $(TODAY)
	echo "# $(TODAY)\n" > $(TODAY)/README.md
	cp $(MAKEFILE_DIR).gitignore $(TODAY)/

.PHONY: all push init create
