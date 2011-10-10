# no user serviceable parts.
# to change the prefix or the destination directory, just specify on command line, as 
# sudo make prefix=/opt/local install
#
version=0.2
package=magithub

prefix         = /usr/local
datarootdir    = $(prefix)/share
lispdir        = $(datarootdir)/emacs/site-lisp
infodir        = $(datarootdir)/info

emacs=emacs
makeinfo=makeinfo

# targets to build info file
info: magithub.info

localinfodir=$${PWD}/info
magithub.info: FORCEINFO magithub.texi
	mkdir $(localinfodir)
	$(makeinfo) -o $(localinfodir)/magithub.info magithub.texi
	install-info --info-dir=$(localinfodir) $(localinfodir)/magithub.info

FORCEINFO:
	-rm -rf $(localinfodir) >/dev/null 2>&1

# targets to build distribution archive
els=magithub.el
distfiles=$(els) Makefile magithub-pkg.el README magithub.texi
infofiles=$(localinfodir)/magithub.info $(localinfodir)/dir
distdir=$(package)-$(version)

dist: $(distfiles) info $(distdir).tar.gz

$(distdir).tar.gz: $(distdir)
	tar chof - $(distdir) | gzip -9 -c > $@
	rm -rf $(distdir)

$(distdir): FORCE
	mkdir -p $(distdir)/info
	cp $(distfiles) $(distdir)
	cp $(infofiles) $(distdir)/info

FORCE:
	-rm $(distdir).tar.gz >/dev/null 2>&1
	-rm -rf $(distdir) >/dev/null 2>&1

# targets to compile elisp file(s)
elcs=$(els:.el=.elc)
all: $(elcs)

batch=$(emacs) -batch -q -no-site-file -eval \
  "(setq load-path (cons (expand-file-name \".\") load-path))"

%.elc: %.el
	$(batch) --eval '(byte-compile-file "$<")'

# this will get actual tests in the future :)
check: all info

# targets for installing - does not depend on build targets so that sudo make install
# will not run make!
install:
	install -d $(DESTDIR)$(lispdir)
	install -m 644 $(els) $(elcs) $(DESTDIR)$(lispdir)
	install -d $(DESTDIR)$(infodir)
	install -m 644 magithub.info $(DESTDIR)$(infodir)
	install-info --info-dir=$(DESTDIR)$(infodir) $(DESTDIR)$(infodir)/magit.info

# targets for uninstalling
uninstall: 
	-rm $(DESTDIR)$(lispdir)/$(els) $(DESTDIR)$(lispdir)/$(elcs)
	-rm $(DESTDIR)$(infodir)/magit.info

# end-user clean
clean:
	rm $(elcs)

# targets to build info file
distcheck: $(distdir).tar.gz
	gzip -cd $(distdir).tar.gz | tar xvf -
	cd $(distdir) && $(MAKE) all
	cd $(distdir) && $(MAKE) check
	cd $(distdir) && $(MAKE) DESTDIR=$${PWD}/_inst install
	cd $(distdir) && $(MAKE) DESTDIR=$${PWD}/_inst uninstall
	@remaining="`find $${PWD}/$(distdir)/_inst -type f | wc -l`"; \
	if test "$${remaining}" -ne 0; then \
		echo "*** $${remaining} file(s) remaining in stage directory!"; \
		exit 1; \
	fi
	cd $(distdir) && $(MAKE) clean
	rm -rf $(distdir)
	@echo "*** Package $(distdir).tar.gz is ready for distribution."

maintainer-clean: FORCE FORCEINFO
	rm $(elcs)

.PHONY: FORCEINFO info dist FORCE all check install uninstall clean distcheck maintainer-check
