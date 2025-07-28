all:
	$(MAKE) init
	$(MAKE) push

push:
	git add -A
	git commit -m "add"
	git push

init:
	echo "REPOS_DIR=$(PWD)" > .env

.PHONY: all push init
