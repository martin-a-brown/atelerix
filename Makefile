# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                           #
#        beginning of multi-VCS package checkout, tarball creation          #
#        package building and OBS handling Makefile section; don't alter!   #
#                                                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                           #
#                   Please do not edit this file.                           #
#             This is not the Makefile you are looking for.                 #
#                      Look for Makefile.build.                             #
#                                                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

# -- Determine working directory and a few other key variables.
#
SHELL           := /bin/bash
DIRNAME         := $(abspath .)
DIRBASE         := $(notdir $(DIRNAME))
SPECFILE        := specfile.in
RPMSPEC         := $(shell which rpmspec 2>/dev/null)
ifeq ($(RPMSPEC),)
       RPMCMD := rpm -q --specfile $(SPECFILE)
else
       RPMCMD := $(RPMSPEC) -q $(SPECFILE)
endif
RPMINFO         := $(shell $(RPMCMD) --queryformat="%{NAME} %{VERSION} %{RELEASE}\n" 2>/dev/null  )
PACKAGE         := $(shell $(RPMCMD) --queryformat="%{NAME}\n" 2>/dev/null | head -n 1)

# -- OK, quick sanity check to make sure that the specfile.in passes
#    muster; normally 'rpm' is informative about errors, so we can just
#    short-circuit any further action if the above has failed.
#
ifeq ($(PACKAGE),)
  $(error Error reading/parsing specfile.in: is it valid? (try: rpm -q --specfile specfile.in))
endif

# -- OK, now keep going, if all is happy so far
#
PACKAGE         := $(word 1, $(RPMINFO))
VERSION         := $(word 2, $(RPMINFO))
RELEASE         := $(word 3, $(RPMINFO))
version_bits    := $(subst ., ,$(VERSION))
MAJOR_VERSION   := $(word 1,$(version_bits))
MAJOR_PACKAGE   := $(PACKAGE)-$(MAJOR_VERSION)
MINOR_VERSION   := $(word 1,$(version_bits)).$(word 2,$(version_bits))
MINOR_PACKAGE   := $(PACKAGE)-$(MINOR_VERSION)
BRANCHNAME      := $(MINOR_PACKAGE)

RPMDIST         := --define "_topdir $(DIRNAME)/build/"
DATE            := $(shell date +%F)
BUILD_HOST      := $(shell hostname)
BUILD_USER      := $(shell id -un)
ENCLAVE         := atelerix

SUBSCRIPT       := substitute.py
SUBDATA         := $(ENCLAVE).subdata
SCM_TYPE        := $(shell test -e .svn && echo svn || { test -e .git && echo git || { test -e .hg && echo hg || { echo test ; } ; } ; } )
CURRENT_PACKAGE := $(PACKAGE)-$(VERSION)
TARBALL         := $(CURRENT_PACKAGE).tar
SRPM            := $(PACKAGE)-$(VERSION)-$(RELEASE).src.rpm
BUILD_MAKEFILE  := Makefile.build
OSCRC           := $(shell echo $$HOME/.oscrc )
OBSUSER         := $(shell python -c 'import ConfigParser, sys; c = ConfigParser.ConfigParser(); c.read(sys.argv[1]) or sys.exit("error reading " + sys.argv[1]); print c.get(c.get("general", "apiurl"), "user")' $(OSCRC) )
OBSPROJECT      := home:$(OBSUSER)
OBSDEFROOT      := ./obs
OBSROOT         := ./obs
EXPORT_EXCL     := .extra-test-build-excludes

export PACKAGE VERSION SPECFILE SUBSCRIPT SUBDATA ENCLAVE

# -- Notes on above variables
#
# SHELL:  should be explicitly set to bash; otherwise build is occasionally
#         suspect to unexpected failures in a foreign shell (the shell in
#         this Makefile is bash)
# DIRNAME:  Required for rpmbuild--rpmbuild cannot deal with relative
#           directories.  Additionally required to determine DIRBASE.
# DIRBASE:  Required for the test build targets.  When attempting a build
#           from the user's home directory, need to fake the pathname to
#           create a tarball.  Therefore need to know what the real name is
#           (probably trunk) and make a symlink to $(PACKAGE)-$(VERSION)
# SPECFILE: Hard-coded name.  Always specfile.in.
# RPMCMD:   The command used to extract NAME and VERSION information from
#           the specfile.in.
# PACKAGE:  Yes, the package name.  Should be set only in specfile.in.
# VERSION:  Yes, the software version.  Should be set only in specfile.in.
# RPMDIST:  Boiler plate option when not using user's build environment.
# DATE:  A string date for substitution at build time.
# BUILD_HOST:  Name of the host on which the software was built.
# BUILD_USER:  Name of the user who built the software (Jack).
# ENCLAVE:  Name of the class of package, e.g. 'renesys', 'atelerix'
# SUBSCRIPT:  The equivalent of 'sed -e' using the subdata file.
# SUBDATA:  The name of the file containing the substitution data.
# SCM_TYPE:  Guessed by the presence of an .svn, .git or .hg directory in $PWD
#            can be specified, e.g. SCM_TYPE=test for working directory builds
# CURRENT_PACKAGE:  Full name of package and version, used for tarball, dir,
#                   branch and tag naming, for example: frobnitz-1.4.2.7.
# MAJOR_VERSION:  Similar; only first component of version, e.g. frobnitz-1
# MINOR_VERSION:  Similar; only first two components, e.g. frobnitz-1.4
# TARBALL:  Name of the tarball (without path).
# BUILD_MAKEFILE:  The well-known name of the Makefile.build.
# OBSPROJECT:  Which OBS project to use as upload target for the package.
# OSCRC:  Configuration file which contains OBS username.
# OBSUSER:  Username to put in meta-information for the package.



# -- Need to add a new variable?
#
#      - Put it here below
#      - export it (so it's available to "child" Makefiles)
#      - throw it in the $(SUBDATA) target for transformations
#
ROOT           := 
USRROOT        := $(ROOT)/usr
VAR            := $(ROOT)/var
ETC            := $(ROOT)/etc
PACKAGE_ETC    := $(ETC)/$(ENCLAVE)/$(PACKAGE)
PACKAGE_ROOT   := $(USRROOT)/lib/$(PACKAGE)
PACKAGE_SHARE  := $(USRROOT)/share/$(PACKAGE)
PACKAGE_SPOOL  := $(VAR)/spool/$(PACKAGE)
PACKAGE_CACHE  := $(VAR)/cache/$(PACKAGE)
PACKAGE_TMP    := $(VAR)/tmp/$(PACKAGE)
LIBEXEC        := $(USRROOT)/libexec
SHARE          := $(USRROOT)/share
MANDIR         := $(USRROOT)/share/man
BINDIR         := $(USRROOT)/bin
SBINDIR        := $(USRROOT)/sbin
NAGIOS_PLUGINS := $(USRROOT)/lib/nagios/plugins
SYSTEMD        := $(USRROOT)/lib/systemd/system
SYSCONFIG      := $(ETC)/sysconfig

export ROOT LIBEXEC SHARE MANDIR ETC BINDIR SBINDIR VAR NAGIOS_PLUGINS
export PACKAGE_ROOT PACKAGE_SHARE PACKAGE_ETC PACKAGE_CACHE PACKAGE_SPOOL
export PACKAGE_TMP DATE BUILD_HOST BUILD_USER
export SYSTEMD SYSCONFIG

# -- weirdo extras
#
APACHE_ROOT=$(shell test -e /etc/SuSE-release && echo /etc/apache2 || echo /etc/httpd)

export APACHE_ROOT

default: build

# -- details needed for various SCM/VCS integration
#
ifeq ($(SCM_TYPE),svn)
  SVN_PATH        := $(shell svn info 2>/dev/null | awk '/^URL:/{print $$2}')
  SVN_PROJ        := $(subst branches/,,$(subst tags/,,$(dir $(SVN_PATH))))
  SVN_PROJSHORT   := $(lastword $(subst /, ,$(SVN_PROJ)))
  ifeq      ($(SVN_PROJSHORT),$(PACKAGE))
  else ifeq ($(SVN_PROJSHORT),$(MAJOR_PACKAGE))
  else ifeq ($(SVN_PROJSHORT),$(MINOR_PACKAGE))
  else ifeq ($(SVN_PROJSHORT),$(CURRENT_PACKAGE))
  else
    $(warning )
    $(warning Discrepancy:)
    $(warning )
    $(warning Specfile shows package name $(PACKAGE) )
    $(warning Subversion has project name $(SVN_PROJSHORT))
    $(warning See SVN path $(SVN_PATH))
    $(warning )
    $(warning Sleeping for 2 seconds before continuing anyway... )
    $(warning )
    $(shell sleep 2)
  endif
else ifeq ($(SCM_TYPE),git)
  GIT_ID          := remotes/svn/$(CURRENT_PACKAGE)
endif


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                           #
#        end of preamble for variable guessing and assignment               #
#                                                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

.SUFFIXES:


# -- the "rpm" target will build out of the SCM, but will leave
#    the resulting package in the relative ./dist/ directory
#
.PHONY: test-rpm testrpm rpm-test rpmtest
test-rpm testrpm rpm-test rpmtest:
	$(MAKE) rpm SCM_TYPE=test

.PHONY: rpm rpms
rpm rpms: rpmlocaldist clean-builddir

.PHONY: srpm
srpm: srpmlocaldist clean-builddir

.PHONY: rpmlocaldist
rpmlocaldist: distdir buildrpm
	mv --verbose \
	    --target-directory ./dist/ \
	    build/$(PACKAGE)-$(VERSION)/$(PACKAGE).spec \
	    build/$(TARBALL).gz \
	    build/RPMS/*/*.rpm \
	    build/SRPMS/$(SRPM)

.PHONY: srpmlocaldist
srpmlocaldist: distdir buildsrpm
	mv --verbose \
	    --target-directory ./dist/ \
	    build/$(PACKAGE)-$(VERSION)/$(PACKAGE).spec \
	    build/$(TARBALL).gz \
	    build/SRPMS/$(SRPM)

.PHONY: buildsrpm
buildsrpm: buildtargz
	rpmbuild $(RPMDIST) -ts ./build/$(TARBALL).gz

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
	  && $(MAKE) specfile

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                  test                                     #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

.PHONY: test-tag
test-tag:
	echo test tag $(CURRENT_PACKAGE)

.PHONY: test-clean
test-clean:
	cd .. \
	  && ( test ! -L "$(CURRENT_PACKAGE)" || rm -f -- "$(CURRENT_PACKAGE)/$(EXPORT_EXCL)" "$(CURRENT_PACKAGE)" )

.PHONY: test-linkname
test-linkname:
	cd .. \
	  && ( test -e "$(CURRENT_PACKAGE)" || ln -snvf -- "$(DIRBASE)" "$(CURRENT_PACKAGE)" )

.PHONY: test-linkname-must-be-pwd
test-linkname-must-be-pwd:
	test ../$(CURRENT_PACKAGE)/ -ef .

# -- There exists general dislike (amongst several people) that this
#    'test-export' target mucks with directories above the $CWD.  That
#    is generally considered bad behaviour
#
.PHONY: test-export
test-export: builddir test-linkname test-linkname-must-be-pwd $(EXPORT_EXCL)
	cd .. \
	  && tar \
	    --create \
	    --dereference \
	    --to-stdout \
	    $(patsubst %,--exclude "$(CURRENT_PACKAGE)/%",$(shell cat $(EXPORT_EXCL) )) \
	    --exclude "*.git*" \
	    --exclude "*.svn*" \
	    --exclude "*.hg*" \
	    --exclude "$(CURRENT_PACKAGE)/obs/*" \
	    --exclude "$(CURRENT_PACKAGE)/dist/*" \
	    --exclude "$(CURRENT_PACKAGE)/build/*" \
	      $(CURRENT_PACKAGE) \
	  | tar \
	    --extract \
	    --directory $(CURRENT_PACKAGE)/build/ \
	    --file -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                   git                                     #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

.PHONY: git-tag
git-tag:
	git tag \
	  -a -m $(CURRENT_PACKAGE) \
	  $(CURRENT_PACKAGE)

.PHONY: git-export
git-export: builddir
	git archive \
	  --format=tar \
	  --prefix=$(CURRENT_PACKAGE)/ \
	  $(GIT_ID) \
	  | tar \
	    --extract \
	    --directory ./build/ \
	    --file -

.PHONY: git-clean
git-clean:

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                   hg                                      #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

# -- support for Mercurial needs more attention, but thanks to
#    estabroo@gmail.com for the beginnings...

.PHONY: hg-export
hg-export: builddir
	hg archive \
	  --prefix=$(CURRENT_PACKAGE)/ \
	  --type=tar \
	  $(HG_ID) \
	  - \
	  | tar \
	    --extract \
	    --directory ./build/ \
	    --file -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                   SVN                                     #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #


# -- ugly shell maneuvering in most of the below to make "nice glue" between
#    'svn' and 'make' which will interpret a non-zero exit as cause for
#    aborting the sequence
#

.PHONY: svn-trunk-must-be-pwd
svn-trunk-must-be-pwd:
	( test trunk == $(lastword $(subst /, ,$(SVN_PATH))) \
	  || { printf >&2 "%s\n" "Working directory must be a ./trunk/ to branch/tag." ; exit 1 ; } )

.PHONY: svn-branch-must-not-exist
svn-branch-must-not-exist:
	( svn ls $(SVN_PROJ)branches/$(BRANCHNAME) >/dev/null 2>&1 \
	  && { printf >&2 "%s\n" "Branch for $(CURRENT_PACKAGE) already exists." ; exit 1 ; } || exit 0 )

.PHONY: svn-tag-must-not-exist
svn-tag-must-not-exist:
	( svn ls $(SVN_PROJ)tags/$(CURRENT_PACKAGE) >/dev/null 2>&1 \
	  && { printf >&2 "%s\n" "Tag for $(CURRENT_PACKAGE) already exists." ; exit 1 ; } || exit 0 )

.PHONY: svn-branch-make svn-branch
svn-branch-make svn-branch: svn-branch-must-not-exist
	svn cp $(SVN_PATH)/ $(SVN_PROJ)branches/$(BRANCHNAME) \
	  -m "branch for $(CURRENT_PACKAGE)"

.PHONY: svn-tag-make svn-tag
svn-tag-make svn-tag: svn-tag-must-not-exist
	svn cp $(SVN_PATH)/ $(SVN_PROJ)tags/$(CURRENT_PACKAGE) \
	  -m "tag for $(CURRENT_PACKAGE)"

.PHONY: svn-export
svn-export: builddir
	cd ./build/ \
	  && svn export $(SVN_PATH) $(CURRENT_PACKAGE)

.PHONY: svn-clean
svn-clean:

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                   OBS                                     #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

.PHONY: obs-clean
obs-clean: clean $(SCM_TYPE)-clean
       test "$(OBSROOT)" == "$(OBSDEFROOT)" && rm -rf -- "$(OBSROOT)/" 2>/dev/null || :

.PHONY: obs-project
obs-project:
	mkdir -p -- $(OBSROOT)/$(OBSPROJECT)

# -- make sure that we got some sort of string for a username from
#    the $HOME/.oscrc before trying a bunch of OBS commands
#
.PHONY: obs-user-from-oscrc
obs-user-from-oscrc:
	test "" != "$(OBSUSER)"

# -- build a new package in the project if it doesn't already exist
#
.PHONY: obs-new
obs-new: obs-user-from-oscrc
	osc meta pkg $(OBSPROJECT) $(PACKAGE) >/dev/null \
	  || { printf "%s\n" \
	      '<package project="$(OBSPROJECT)" name="$(PACKAGE)">' \
	      '  <title>$(PACKAGE)</title>' \
	      '  <description/>' \
	      '  <person role="maintainer" userid="$(OBSUSER)"/>' \
	      '  <person role="bugowner" userid="$(OBSUSER)"/>' \
	      '  <url/>' \
	      '</package>' \
	        | osc meta pkg $(OBSPROJECT) $(PACKAGE) --create --file - ; }

.PHONY: obs-checkout
obs-checkout: obs-project
	cd $(OBSROOT)/$(OBSPROJECT)/ \
	  && osc checkout --current-dir -- $(OBSPROJECT) $(PACKAGE)

.PHONY: obs-update
obs-update:
	( test -d $(OBSROOT)/$(OBSPROJECT)/$(PACKAGE)/ || $(MAKE) obs-checkout )
	cd $(OBSROOT)/$(OBSPROJECT)/$(PACKAGE)/ && osc update

.PHONY: obs-removeold
obs-removeold:
	find $(OBSROOT)/$(OBSPROJECT)/$(PACKAGE)/ \
	  -mindepth 1 \
	  -maxdepth 1 \
	  -type f \
	  -name '*.tar.gz' \
	  -not -name '$(TARBALL).gz' \
	  -print0 \
	    | xargs --null --no-run-if-empty -- rm -v --

.PHONY: obs-extractsrpm
obs-extractsrpm: srpmlocaldist
	rpm2cpio < ./dist/$(SRPM) \
	    | ( cd $(OBSROOT)/$(OBSPROJECT)/$(PACKAGE)/ && cpio --extract --verbose --unconditional )

.PHONY: obs-addremove
obs-addremove:
	cd $(OBSROOT)/$(OBSPROJECT)/$(PACKAGE)/ && osc addremove

.PHONY: obs-commit
obs-commit:
	cd $(OBSROOT)/$(OBSPROJECT)/$(PACKAGE) \
	  && osc commit -m "$(BUILD_USER)@$(BUILD_HOST) uploads $(PACKAGE)-$(VERSION) to $(OBSPROJECT)"

.PHONY: obs
obs: srpm obs-project obs-new obs-update obs-removeold obs-extractsrpm obs-addremove obs-commit

.PHONY: test-obs testobs obstest obs-test
test-obs testobs obstest obs-test:
	$(MAKE) obs SCM_TYPE=test

.PHONY: obs-dev obsdev
obs-dev obsdev:
	$(MAKE) obs OBSPROJECT=dev:internal

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                               generic build                               #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

.PHONY: branch
branch: $(SCM_TYPE)-branch

.PHONY: tag
tag: $(SCM_TYPE)-tag

.PHONY: clean mrclean
clean mrclean: $(SUBDATA) build-clean pkg-clean

.PHONY: pkg-clean
pkg-clean:
	rm -f -- $(SUBSCRIPT) $(SUBDATA) $(PACKAGE).spec

.PHONY: builddir
builddir:
	rm -rf -- ./build/
	mkdir -p -- ./build/{SPECS,SOURCES,RPMS,SRPMS,BUILD}

.PHONY: distdir
distdir:
	rm -rf -- ./dist/
	mkdir -p ./dist

.PHONY: clean-builddir
clean-builddir: clean $(SCM_TYPE)-clean
	rm -rf -- ./build/ 2>/dev/null || :

.PHONY: clean-distdir
clean-distdir: clean $(SCM_TYPE)-clean
	rm -rf -- ./dist/ 2>/dev/null || :

.PHONY: distclean
distclean: obs-clean clean-builddir clean-distdir test-clean

.PHONY: specfile
specfile: $(SUBSCRIPT) $(SUBDATA) $(SPECFILE)
	python $(SUBSCRIPT) $(SUBDATA) < $(SPECFILE) > $(PACKAGE).spec

.PHONY: vars
vars: $(SUBDATA)
	cat $(SUBDATA)

$(SUBSCRIPT): Makefile
	@printf > $(SUBSCRIPT) "%s\n" \
	"#! /usr/bin/env python" \
	"import sys" \
	"" \
	"" \
	"def transform(mapping, text):" \
	"    for tag, replacement in mapping.iteritems():" \
	"        text = text.replace(tag, replacement)" \
	"    return text" \
	"" \
	"if 2 != len(sys.argv):" \
	"    sys.exit('usage: ' + sys.argv[0] + '<substitution_file>')" \
	"subst = dict(SUBDATA=sys.argv[1])" \
	"for line in open(sys.argv[1]):" \
	"    if line.startswith('#'):" \
	"        continue" \
	"    line = line.strip()" \
	"    if line == '':" \
	"        continue" \
	"    parts = line.split(None, 1)" \
	"    if len(parts) == 2:" \
	"        (k, v) = parts" \
	"    else:" \
	"        k = parts[0]" \
	"        v = ''" \
	"    k = '@' + k.strip() + '@'" \
	"    subst[k] = transform(subst, v.strip())" \
	"sys.stdout.write(transform(subst, sys.stdin.read()))" \
	"# -- end of file"

.PHONY: subdata $(SUBDATA)
subdata $(SUBDATA): pkg-$(SUBDATA) $(SUBDATA)-hook

pkg-$(SUBDATA):
	@printf > $(SUBDATA) "%s\t%s\n" \
	  PACKAGE        "$(PACKAGE)" \
	  VERSION        "$(VERSION)" \
	  MAJOR_VERSION  "$(MAJOR_VERSION)" \
	  MAJOR_PACKAGE  "$(MAJOR_PACKAGE)" \
	  MINOR_VERSION  "$(MINOR_VERSION)" \
	  MINOR_PACKAGE  "$(MINOR_PACKAGE)" \
	  DATE           "$(DATE)" \
	  BUILD_HOST     "$(BUILD_HOST)" \
	  BUILD_USER     "$(BUILD_USER)" \
	  RELEASE_DIST   "$(RELEASE_DIST)" \
	  ROOT           "$(ROOT)" \
	  NAGIOS_PLUGINS "$(NAGIOS_PLUGINS)" \
	  PACKAGE_ROOT   "$(PACKAGE_ROOT)" \
	  PACKAGE_SHARE  "$(PACKAGE_SHARE)" \
	  PACKAGE_CACHE  "$(PACKAGE_CACHE)" \
	  PACKAGE_SPOOL  "$(PACKAGE_SPOOL)" \
	  PACKAGE_ETC    "$(PACKAGE_ETC)" \
	  PACKAGE_TMP    "$(PACKAGE_TMP)" \
	  APACHE_ROOT    "$(APACHE_ROOT)" \
	  LIBEXEC        "$(LIBEXEC)" \
	  MANDIR         "$(MANDIR)" \
	  BINDIR         "$(BINDIR)" \
	  SBINDIR        "$(SBINDIR)" \
	  ETC            "$(ETC)" \
	  VAR            "$(VAR)" \
	  SHARE          "$(SHARE)"\
	  SYSTEMD        "$(SYSTEMD)"\
	  SYSCONFIG      "$(SYSCONFIG)"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                    user-controlled per package stuff                      #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

include $(BUILD_MAKEFILE)

# -- documentation target(s)
#
.PHONY: help
help:
	@printf "%s\n" \
	"Makefile for atelerix-based packages" \
	"--------------------------------------" \
	"" \
	"make" \
	"make build" \
	"  Default behaviour (when no target is specified) is to call the 'build'" \
	"  target.  This creates the derived files, turning PROGGIE.in into PROGGIE." \
	"  When you call 'make build', the variables file called '$(SUBDATA)'" \
	"  is created and then the Makefile.build 'build' target is called." \
	"" \
	"make rpm" \
	"  Specifying the 'rpm' target will cause the packages to be built into" \
	"  the relative directory ./build/.  If the build is succesful, the" \
	"  tarball, specfile, RPM and SRPM will be found in the ./dist/" \
	"  directory." \
	"" \
	"make rpmdist" \
	"  If you have a build environment configured, you can specify the 'rpmdist'" \
	"  target and the environment-specified .rpmmacros will be honored, leaving" \
	"  the resulting packages in the environment configured RPM tree," \
	"  thus allowing you to build directly into an existing RPM-MD repository." \
	"  Useful if you already have a build environment you wish to use." \
	"  Supported, but (possibly) superfluous target, see instead 'obs' target." \
	"" \
	"make testrpm" \
	"  This builds the package straight out of the current working directory." \
	"  That allows you to test that the package builds cleanly before checking" \
	"  in any code.  This target creates a tarball from your working directory." \
	"  If you have large data files that are not part of the package, you can" \
	"  create a file called '$(EXPORT_EXCL)' which should list the" \
        "  files to add to the --exclude params for the tar command." \
	"" \
	"make rpm SCM_TYPE=test" \
	"make test-rpm" \
	"  These are synonyms for 'make testrpm'" \
	"" \
	"make branch" \
	"  The result is that you have captured a snapshot of the current release" \
	"  of the software in subversion, and it can be rebuilt from that branch." \
	"  You can then continue developing against ./trunk/ or your new branch." \
	"  By default a branch for this package would be $(BRANCHNAME)." \
	"  You can override the default branch name with a variable, for example:" \
 	"" \
	"    'make branch BRANCHNAME=hairy_ogre-0.7.5'" \
 	"" \
	"make tag" \
	"  After you have checked that your package builds, using 'make testrpm'," \
	"  and you have adjusted the version number in specfile.in and committed" \
	"  that specfile.in, you can take advantage of the 'make tag' feature." \
	"  When you call 'make tag', the Makefile runs a few sanity checks and" \
	"  then creates a tag for the current version of the package." \
 	"" \
	"make rpm SCM_TYPE=svn" \
	"  Atelerix tries to guess your VCS, but you can override it.  Thus," \
	"  by default, this package uses SCM_TYPE=$(SCM_TYPE).  You can control" \
	"  which SCM_TYPE you would like to use for the build of this package by" \
	"  setting the SCM_TYPE package type on the command line." \
	"" \
	"make rpm SCM_TYPE=git" \
	"make rpm SCM_TYPE=git GIT_ID=HEAD" \
	"  If you live in the future, you may already be using 'git' (or 'git-svn')" \
	"  and, therefore, can use GIT_IDs to build packages straight out of your" \
	"  cloned git repo." \
	"" \
	"make obs" \
	"  Atelerix can push to the Open Build Service software to manage software" \
	"  build and distribution.  Calling this target will build the package" \
	"  straight from the version control system and upload the result into" \
	"  the specified OBS project (default is $(OBSPROJECT))." \
	"" \
	"  N.B. For the OBS targets, it is required that the user have already" \
	"  configured a $(OSCRC) and a working 'osc' CLI access to the build" \
	"  service instance." \
 	"" \
	"make obsdev    # (also 'obs-dev')" \
	"  A few convenience targets for sending packages to internal " \
	"  infrastructure. This target will build in the OBS project 'dev:internal'." \
 	"" \
	"make testobs" \
	"  This is shorthand for 'make obs SCM_TYPE=test', which builds the" \
	"  current working directory as a package and then uploads that result" \
	"  into the specified OBS project." \
 	"" \
	"Make Variables:" \
	"  SCM_TYPE:    source control manager, default here is '$(SCM_TYPE)'" \
	"  GIT_ID:      a git hash ID, refers to tag/branch, default is '$(GIT_ID)'" \
	"  OBSUSER:     username for new OBS packages, default from ~/.oscrc" \
	"  OBSPROJECT:  project for this package, defaults to '$(OBSPROJECT)'" \
 	"" \
	"make build" \
	"make install" \
	"make tests" \
	"make docs" \
	"make some_random_other_thing" \
	"  These targets are handled in Makefile.build.  If you are using this " \
	"  and you happen not have rpm available, you might stick a dummy script " \
	"  named 'rpm' somewhere it will be found so that you can still 'make tests'" \
	"  or 'make docs'." \
	"  e.g.  printf \"%s\\n\" '#!/bin/sh' 'echo dummy rpm' > ~/bin/rpm \\" \
	"        && chmod +x ~/bin/rpm && echo 'make sure ~/bin/ is on your PATH!'" \
 	"" \
	"make help" \
	"  Print this out." \
	""
 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                           #
#                             end of Makefile                               #
#                                                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
