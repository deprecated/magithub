##################################
# adjust as needed to your system
##################################

# your emacs binary
EMACS = emacs

# where local software is installed
prefix         = /usr/local
datarootdir    = $(prefix)/share

# where local lisp files go
lispdir        = $(datarootdir)/emacs/site-lisp

# where info files go
infodir        = $(datarootdir)/info

##################################
# you MAY need to edit these
##################################

BATCH = $(EMACS) -batch -q -no-site-file -eval \
  "(setq load-path (cons (expand-file-name \".\") load-path))"

magithub.elc: magithub.el
	$(BATCH) --eval '(byte-compile-file "magithub.el")'

MKDIR = mkdir -p

CP = cp -p

MAKEINFO = makeinfo

INSTALL_INFO = install-info

##################################
# touch at your own peril!!
##################################

version=0.2
package=magithub

# targets to build info file
info: magithub.info

# without the quotes, breaks on macs - spaces in directory name
localinfodir="$${PWD}"/info

magithub.info: FORCEINFO magithub.texi
	$(MKDIR) $(localinfodir)
	$(MAKEINFO) -o $(localinfodir)/magithub.info magithub.texi
	$(INSTALL_INFO) --info-dir=$(localinfodir) $(localinfodir)/magithub.info

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

$(distdir): FORCEDIST
	$(MKDIR) $(distdir)/info
	$(CP) $(distfiles) $(distdir)
	$(CP) $(localinfodir)/magithub.info $(localinfodir)/dir $(distdir)/info

FORCEDIST:
	-rm $(distdir).tar.gz >/dev/null 2>&1
	-rm -rf $(distdir) >/dev/null 2>&1

# targets to compile elisp file(s)
elcs=$(els:.el=.elc)
compile: $(elcs)

all: compile info

# this will get actual tests in the future :)
check: all

# targets for installing - does not depend on build targets so that sudo make install
# will not run make!
install-lisp:
	install -d $(DESTDIR)$(lispdir)
	install -m 644 $(els) $(elcs) $(DESTDIR)$(lispdir)

install-info:
	install -d $(DESTDIR)$(infodir)
	install -m 644 magithub.info $(DESTDIR)$(infodir)
	install-info --info-dir=$(DESTDIR)$(infodir) $(DESTDIR)$(infodir)/magit.info

install: install-lisp install-info

# targets for uninstalling
uninstall: 
	-rm $(DESTDIR)$(lispdir)/$(els) $(DESTDIR)$(lispdir)/$(elcs)
	-rm $(DESTDIR)$(infodir)/magit.info

# check dist target
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
	rm -rf $(distdir)
	@echo "*** Package $(distdir).tar.gz is ready for distribution."

# end-user clean
clean: FORCEINFO
	rm $(elcs)

maintainer-clean: FORCEDIST FORCEINFO
	rm $(elcs)

.PHONY: FORCEINFO info dist FORCEDIST compile all check install-lisp install-info install uninstall clean distcheck maintainer-clean help

help:
	@echo "Usage: make all - compile Magithub ELisp and Info files"
	@echo "       make compile - compile Magithub ELisp files"
	@echo "       make info - compile Magithub Info files"
	@echo ""
	@echo "       make install - install Magithub ELisp and Info files"
	@echo "       make install-lisp - install Magithub ELisp files"
	@echo "       make install-info - install Magithub Info files"
	@echo ""
	@echo "       make uninstall - remove Magithub ELisp and Info files"
	@echo ""
	@echo "       make clean - restart make process"