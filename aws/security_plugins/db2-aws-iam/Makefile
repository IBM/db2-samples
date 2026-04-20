.PHONY: all
all:
	$(MAKE) -C src gss

.PHONY: plugin
plugin: 
	$(MAKE) -C src gss


.PHONY: clean
clean:
	$(MAKE) -C src cleangss
	$(MAKE) -C src cleanum


.PHONY: install
install: 
	$(MAKE) -C src install

.PHONY: remove
remove:
	$(MAKE) -C src remove

.PHONY: test
test:
	$(MAKE) -C src/test

.PHONY: tail
tail:
	tailf ~/sqllib/db2dump/db2diag.log  | grep gssapi

