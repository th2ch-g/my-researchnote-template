MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

all:
	$(MAKE) init
	$(MAKE) push

push:
	git add -A
	git commit -m "add"
	git push

init:
	echo "REPOS_DIR=$(PWD)" > .env

create:
	# touch .gitignore
	cp $(MAKEFILE_DIR).gitignore .

.PHONY: all push init create
