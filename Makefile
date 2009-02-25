# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                           #
#        beginning of multi-VCS package checkout, tarball creation          #
#        and package building Makefile section                              #
#                                                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                           #
#   This is probably not the Makefile you are looking for.                  #
#                                                                           #
#   Go find 'Makefile.build' in this directory.                             #
#                                                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

# -- Determine working directory and a few other key variables.
#
SHELL      := /bin/bash
DIRNAME    := $(shell echo $${PWD})
DIRBASE    := $(shell basename $${PWD})
SPECFILE   := specfile.in
CMD        := rpm -q --specfile $(SPECFILE)
PACKAGE    := $(shell $(CMD) --queryformat="%{NAME}\n" | head -n 1)
VERSION    := $(shell $(CMD) --queryformat="%{VERSION}\n" | head -n 1)
RPMDIST    := --define "_topdir $(DIRNAME)/build/"
DATE       := $(shell date +%F)
BUILD_HOST := $(shell hostname)
BUILD_USER := $(shell id -un)
SUBSCRIPT  := substitute.py
BUILD_TYPE := conventional
SUBDATA    := subdata.$(BUILD_TYPE)
ENCLAVE    := atelerix

export PACKAGE VERSION SPECFILE SUBSCRIPT SUBDATA

# -- conditional build/installation target logic (extracted)
#
RELEASE_DIST   :=
ROOT           := 
USRROOT        := $(ROOT)/usr

# -- Need to add a new variable?
#
#      - Put it here below
#      - export it (so it's available to "child" Makefiles)
#      - throw it in the $(SUBDATA) target for transformations
#
VAR            := $(ROOT)/var
ETC            := $(ROOT)/etc
PACKAGE_ETC    := $(ETC)/$(ENCLAVE)/$(PACKAGE)
PACKAGE_ROOT   := $(USRROOT)/lib/$(PACKAGE)
PACKAGE_SHARE  := $(USRROOT)/share/$(PACKAGE)
PACKAGE_CACHE  := $(VAR)/spool/$(PACKAGE)
PACKAGE_TMP    := $(VAR)/tmp/$(PACKAGE)
LIBEXEC        := $(USRROOT)/libexec
SHARE          := $(USRROOT)/share
MANDIR         := $(USRROOT)/share/man
BINDIR         := $(USRROOT)/bin
SBINDIR        := $(USRROOT)/sbin

export RELEASE_DIST ROOT LIBEXEC SHARE MANDIR ETC BINDIR SBINDIR VAR
export PACKAGE_ROOT PACKAGE_SHARE PACKAGE_ETC PACKAGE_CACHE PACKAGE_TMP
export DATE BUILD_HOST BUILD_USER

# -- weirdo extras
#
APACHE_ROOT=$(shell test -e /etc/SuSE-release && echo /etc/apache2 || echo /etc/httpd)

export APACHE_ROOT

default: rpm

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                           #
#        end of preamble for package building out of git/svn/cvs            #
#                                                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

SCM_TYPE := git
CVS_PATH := $(shell cat 2>/dev/null CVS_PATH)
SVN_PATH := $(shell svn info 2>/dev/null | awk '/^URL:/{print $$2}')

CURRENT_PACKAGE := $(PACKAGE)-$(VERSION)
TARBALL         := $(CURRENT_PACKAGE).tar
BUILD_MAKEFILE  := Makefile.build
GIT_ID          := $(CURRENT_PACKAGE)
CVS_ID          := $(subst .,-, $(CURRENT_PACKAGE))

.SUFFIXES:

.PHONY: build-clean
build-clean: $(SUBDATA)
	rm -f $(PACKAGE).spec
	$(MAKE) -f $(BUILD_MAKEFILE) build-clean

.PHONY: build
build: $(SUBDATA)
	$(MAKE) -f $(BUILD_MAKEFILE) build

.PHONY: install
install: $(SUBDATA)
	$(MAKE) -f $(BUILD_MAKEFILE) install

# -- the "rpmdist" target will build out of the SCM, but will
#    use the user's default build settings (which in many cases
#    is exposed as an RPM repository)
#
.PHONY: rpmdist
rpmdist: dist-rpm

.PHONY: dist-rpm
dist-rpm:
	$(MAKE) buildrpm BUILD_TYPE=conventional RPMDIST=
	$(MAKE) distclean

# -- the "rpm" target will build out of the SCM, but will leave
#    the resulting package in the relative ./build/ directory
#
.PHONY: rpm
rpm: rpmlocaldist $(SCM_TYPE)-clean

.PHONY: rpms
rpms: rpm

.PHONY: test-rpm
test-rpm:
	$(MAKE) rpm SCM_TYPE=test

.PHONY: rpmlocaldist
rpmlocaldist: distdir buildrpm
	mv --verbose \
	    --target-directory ./dist/ \
	    build/$(CURRENT_PACKAGE).tar.gz \
	    build/RPMS/*/$(CURRENT_PACKAGE)*.rpm \
	    build/SRPMS/$(CURRENT_PACKAGE)*.rpm

.PHONY: buildrpm
buildrpm: buildtargz
	rpmbuild $(RPMDIST) -ta ./build/$(TARBALL).gz

.PHONY: buildtargz
buildtargz: buildtarball
	gzip -c < ./build/$(TARBALL) > ./build/$(TARBALL).gz

.PHONY: buildtarball
buildtarball: buildselectionhook
	tar \
	  --create \
	  --directory ./build/ \
	  --file      ./build/$(TARBALL) \
	  $(PACKAGE)-$(VERSION)

.PHONY: buildselectionhook
buildselectionhook: $(SCM_TYPE)-export
	cd ./build/$(CURRENT_PACKAGE) \
	  && $(MAKE) specfile-$(BUILD_TYPE)

# -- integration with a variety of different SCMs below
#
.PHONY: tag
tag: $(SCM_TYPE)-tag

.PHONY: test-clean
test-tag:
	echo test tag $(CURRENT_PACKAGE)

.PHONY: test-clean
test-clean:
	cd .. \
	  && rm "$(CURRENT_PACKAGE)"

.PHONY: test-export
test-export: builddir prepclean
	cd .. \
	  && ln -snvf $(DIRBASE) $(CURRENT_PACKAGE) \
	  && tar \
	    --create \
	    --dereference \
	    --to-stdout \
	    --exclude "*.git*" \
	    --exclude "*.svn*" \
	    --exclude "*/CVS/*" \
	    --exclude "$(CURRENT_PACKAGE)/dist/*" \
	    --exclude "$(CURRENT_PACKAGE)/build/*" \
	      $(CURRENT_PACKAGE) \
	  | tar \
	    --extract \
	    --directory $(CURRENT_PACKAGE)/build/ \
	    --file -

.PHONY: git-tag
git-tag:
	git-tag \
	  -a -m $(CURRENT_PACKAGE) \
	  $(CURRENT_PACKAGE)

.PHONY: git-export
git-export: builddir prepclean
	git-archive \
	  --format=tar \
	  --prefix=$(CURRENT_PACKAGE)/ \
	  $(GIT_ID) \
	  | tar \
	    --extract \
	    --directory ./build/ \
	    --file -

.PHONY: git-clean
git-clean:

.PHONY: cvs-tag
cvs-tag:
	cvs tag -c $(CVS_ID)

.PHONY: cvs-export
cvs-export: builddir prepclean
	cd ./build/ \
	  && cvs export -r $(CVS_ID) -d $(CURRENT_PACKAGE) $(PACKAGE)

.PHONY: cvs-clean
cvs-clean:

.PHONY: svn-trunk-must-be-pwd
svn-trunk-must-be-pwd:
	test ../trunk/ -ef .

.PHONY: svn-tag-must-not-exist
svn-tag-must-not-exist:
	test ! -e ../tags/$(CURRENT_PACKAGE)

.PHONY: svn-update
svn-update:
	svn update

.PHONY: svn-tag
svn-tag: svn-trunk-must-be-pwd svn-tag-must-not-exist svn-update
	svn cp ../trunk ../tags/$(CURRENT_PACKAGE) \
	  && svn commit -m $(CURRENT_PACKAGE) ../tags/$(CURRENT_PACKAGE)

.PHONY: svn-export
svn-export: builddir prepclean
	cd ./build/ \
	  && svn export $(SVN_PATH) $(CURRENT_PACKAGE)

.PHONY: svn-clean
svn-clean:

.PHONY: builddir
builddir:
	mkdir -p ./build/{SPECS,SOURCES,RPMS,SRPMS,BUILD}

.PHONY: distdir
distdir:
	mkdir -p ./dist

.PHONY: prepclean
prepclean:
	rm -rf ./build/$(CURRENT_PACKAGE)*

.PHONY: clean
clean: build-clean
	rm -rf subdata.$(BUILD_TYPE) ./build/* ./dist/* 2>/dev/null || :

.PHONY: mrclean
mrclean: clean

.PHONY: distclean
distclean: clean $(SCM_TYPE)-clean
	rmdir ./build/ ./dist/ 2>/dev/null || :

# -- our own recursively called targets
#
.PHONY: specfile
specfile: $(SUBDATA)
	python $(SUBSCRIPT) $(SUBDATA) < $(SPECFILE) > $(PACKAGE).spec

.PHONY: specfile-conventional
specfile-conventional: specfile

.PHONY: $(SUBDATA)
$(SUBDATA):
	@printf > $(SUBDATA) "%-20s %s\n" \
	  PACKAGE        "$(PACKAGE)" \
	  VERSION        "$(VERSION)" \
	  DATE           "$(DATE)" \
	  BUILD_HOST     "$(BUILD_HOST)" \
	  BUILD_USER     "$(BUILD_USER)" \
	  RELEASE_DIST   "$(RELEASE_DIST)" \
	  ROOT           "$(ROOT)" \
	  PACKAGE_ROOT   "$(PACKAGE_ROOT)" \
	  PACKAGE_SHARE  "$(PACKAGE_SHARE)" \
	  PACKAGE_CACHE  "$(PACKAGE_CACHE)" \
	  PACKAGE_ETC    "$(PACKAGE_ETC)" \
	  PACKAGE_TMP    "$(PACKAGE_TMP)" \
	  APACHE_ROOT    "$(APACHE_ROOT)" \
	  LIBEXEC        "$(LIBEXEC)" \
	  MANDIR         "$(MANDIR)" \
	  BINDIR         "$(BINDIR)" \
	  SBINDIR        "$(SBINDIR)" \
	  ETC            "$(ETC)" \
	  VAR            "$(VAR)" \
	  SHARE          "$(SHARE)"
	$(MAKE) -f $(BUILD_MAKEFILE) $(SUBDATA)-hook


# -- documentation target(s)
#
.PHONY: help
help:
	@printf "%s\n" \
	"Makefile for atelerix-based packages" \
	"------------------------------------" \
	"Valid targets are 'rpm', 'rpms' and 'rpmdist'." \
	"" \
	"  rpm     ('make rpm'):" \
	"  rpms    ('make rpms'):" \
	"" \
	"Specifying (either of) these targets will cause the packages to be" \
        "built into the relative directory ./build/.  If the build is succesful," \
        "the resulting RPM and SRPMs will be moved into the ./dist/ directory." \
	"" \
	"  rpmdist ('make rpmdist'):" \
	"" \
	"Specifying this target will not override the user-configured RPM build," \
	"environment thus allowing the user to build directly into an existing RPM-MD" \
        "repository.  Useful if you already have a build environment you wish to use." \
	"" \
	"By default, this package uses SCM_TYPE=$(SCM_TYPE).  You can control" \
	"which SCM_TYPE you would like to use for the build of this package by" \
	"setting the SCM_TYPE package type on the command line.  Here's how" \
	"you can build out of a working directory without checking in code:" \
	"" \
	"  make rpm SCM_TYPE=test" \
	"" \
	"Because building a test package is such a common pattern (building from" \
	"a working directory), there is a target just for building such a package," \
	"which is an exact analog of the above command." \
	"" \
	"  make test-rpm" \
	"" \
	"Let's say you're a total CVS aficionado and you cannot stand to be" \
	"without your horribly broken VCS.  Well, you can still have the worst" \
	"of the old world (but you'll have to commit a file called CVS_PATH" \
	"which contains the CVS checkout path, silly)" \
	"" \
	"  make rpm SCM_TYPE=cvs" \
	"" \
	"If you are using git, the rules are pretty much the same:" \
	"" \
	"  make rpm SCM_TYPE=git" \
	"  make rpm SCM_TYPE=git GIT_ID=HEAD" \
	"" \

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                           #
#                             end of Makefile                               #
#                                                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
