===============
PACKAGING-HOWTO
===============

:Authors:
  Martin A. Brown

:Copyright:
  Copyright © Martin A. Brown

:Date: 2009-02-24

.. sectnum::

Abstract
--------
This is an example package.  It provides a simple mechanism for building
packages that are composed of (primarily) scripts, configuration files and
other simple interdependent utilities.  This abstracts the building of
packages and provides two files for package description for the developer.

It affords reproducible builds for operations (by building directly from the
source code management system).


.. contents:: Table of Contents
   :depth: 5

Building
--------
The example package can be used as a template for any other package.  See the
section `Creating a new package`_ for details on how to adapt this package to
your own project.

Quickstart
++++++++++

In order to build an RPM, you should only need a base system,rpmbuild, python
and GNU make.

  make rpm

Build process
+++++++++++++

  #. Go to the package directory: ``cd atelerix``.

  #. Type ``make``.  This will build a package.  The default target is 'rpm',
     which is a conventionally packaged RPM (FHS-style, with minor
     modifications).

  #. Find the RPM in the ./dist/ directory.

  #. Type ``make distclean`` to clean up after the build (this will blow away
     the ./dist/ and ./build/ directories, so if you want anything from them,
     grab that before you type ``make distclean``.


Using the template
------------------

Creating a new package
++++++++++++++++++++++

  #. Copy the template to a new directory (assuming new package called
     frobnitz). ::
     
       cp -rav path/to/the/example-packaging/simple/ frobnitz
       cd frobnitz

  #. Modify the specfile and change the name of the package from 'example'
     to 'frobnitz'.

  #. Build the package with ``make rpm``.

  #. Find the package in ``./dist/``.

Now, you have a completely new package which is named 'frobnitz'.


Features of the example package
+++++++++++++++++++++++++++++++

  * The supplied (example) Makefile.build supports the POD files and POD files
    embedded in perl programs for writing manpages.  This could be extended to
    support other input formats (e.g. rst, asciidoc).

Examples
--------
Below are a few examples for how to add certain kinds of content to a package.

Adding a configuration file
+++++++++++++++++++++++++++

If any of your scripts need a configuration file (separate from configuration
data passed via environment variables), you may use the ``@PACKAGE_ETC@``
macro and directory.  Here's an example script called ``frobnitz`` which will
need to read a configuration file.

  #. Make your program name ``frobnitz.in``.

  #. Add ``frobnitz`` to ``BUILT_FILES`` in ``Makefile.build``. ::

       BUILT_FILES := frobnitz``

  #. Add the configuration file ``main.conf`` to the repository.

  #. Install the configuration file ``main.conf`` in the install target. ::

       install:
           mkdir -p $(DESTDIR)$(PACKAGE_ETC)
           install -m 0644 main.conf $(DESTDIR)$(PACKAGE_ETC)

  #. Add the configuration file and directory to ``specfile.in``.  ::

     %dir                   @PACKAGE_ETC@
     %config(noreplace)     @PACKAGE_ETC@/main.conf

Adding a manpage
++++++++++++++++

  #. If any of your scripts include inline POD (for manpage generation), you
     need only specify this in your ``Makefile.build``.  Find the line that
     says ``MANPAGES :=`` and add your program name with a .1, e.g.  ::

       MANPAGES := proggie.1

  #. Now, add two lines to the install target that look like this:  ::

       mkdir -p $(DESTDIR)$(MANDIR)/man1
       install -m 0644 proggie.1 $(DESTDIR)$(MANDIR)/man1

  #. And, finally, add a line in the ``%files`` section of the ``specfile.in``
     that refers to the newly added documentation, e.g. ::
 
       @MANDIR@/man1/rat.1*


Adding an Apache configuration file
+++++++++++++++++++++++++++++++++++

The below instructions assume that your CGI is going to be installed in your
``@PACKAGE_ROOT@`` and be called ``frobnitz.py``.

  #. Identify the URL path on which your application will respond to requests.
     (Let's assume that this is ``/MyFrobnitzCGI``.

  #. Add a file called ``frobnitz.conf.in`` to your package with the following
     contents. ::

       <Directory "@PACKAGE_ROOT@">
         Options +ExecCGI -Includes -Indexes -MultiViews -FollowSymLinks
         Order allow,deny
         Allow from all
       </Directory>

       ScriptAliasMatch /MyFrobnitzCGI(.*$) "@PACKAGE_ROOT@/frobnitz.py$1"

  #. Add the following snippet to the install target of ``Makefile.build``: ::
     
       mkdir -p $(DESTDIR)$(APACHE_ROOT)/conf.d
       install -m 0644 frobnitz.conf $(DESTDIR)$(APACHE_ROOT)/conf.d

  #. Add the following snippet to the ``%files`` section of ``specfile.in``: ::

       %config(noreplace)     @APACHE_ROOT@/conf.d/frobnitz.conf


Adding a daemontools service
++++++++++++++++++++++++++++

  #. Add a file called ``renserv.cfg.in`` to your package.

  #. Add, at absolute least, the first two lines, which define the software
     (and version, if you must) and the user as which the software will
     run. ::

       SERVICE=@PACKAGE@
       USER=gradus

  #. Add a ``start.in`` file which calls your daemon software (preferably with
     an ``exec your-daemon``).

  #. Modify your ``Makefile.build`` install target to look like this: ::

       mkdir -p $(DESTDIR)$(PACKAGE_SHARE)
       install -m 0644 renserv.cfg $(DESTDIR)$(PACKAGE_SHARE)
       #
       # -- install the start files for the daemontools services
       #
       mkdir -p $(DESTDIR)$(LIBEXEC)
       install -m 0755 start $(DESTDIR)$(LIBEXEC)/start-$(PACKAGE)
       install -m 0755 start $(DESTDIR)$(LIBEXEC)/start-$(PACKAGE)-$(VERSION)

Potential ``Makefile`` targets
------------------------------

  * ``build``

    Since this isn't traditional C-style software, no compiler is needed, but
    this performs the replacements of the macros with the required targets.
    For example, if you have a file (``start.in``) which is used to generate
    a ``start`` file, the transformation of ``@PACKAGE@`` into ``frobnitz`` is
    made with this target.

    The ``Makefile`` calls the ``Makefile.build`` for this target.  The
    ``Makefile.build`` file must include a ``build`` target.  The default
    ``build`` target looks like this: ::

        build: $(SUBDATA) $(BUILT_FILES) $(MANPAGES)

    This single line means that any files in $(BUILT_FILES) or $(MANPAGES)
    will be built when the ``build`` target is called.


  * ``install``

    This is the most important target for the developer.  The developer is in
    complete control of the locations for the software.  See the section on
    the available `Macros for directories`_ to choose which directory may be
    appropriate for a given file (config file, data or code).

  * ``dist-rpm``

    The ``dist-rpm`` target will build a conventional RPM to the user's
    configured RPM build area.  This is convenient for building packages
    straight into an RPM repository accessible to the installed hosts.

  * ``rpm``

    Build the conventional package.  It will be found under ./dist/.

  * ``rpms``

    Synonym for ``rpm``.

  * ``rpmdist``

    Build packages, but use the user's RPM build environment (mostly relevant
    for building into an RPM-MD repository).


Macros for directories
----------------------

The macros are available in both ``specfile.in`` and also in
``Makefile.build``.  The macros have a slightly different syntax in each of
these files.  In all of the below, imagine a package called
``frobnitz-0.1.42``.

In ``Makefile.build``, use ``$(PACKAGE_ROOT)``.
In ``specfile.in`` and any ``*.in`` code, use ``@PACKAGE_ROOT@``.

  * ``PACKAGE``: ``frobnitz`` (e.g.)

    This variable will contain the name of the package as obtained from the
    ``specfile.in``.  This is the only place the name of the package needs to
    be entered.  In our example case, this would be ``frobnitz``.

  * ``VERSION``:  ``0.1.42`` (e.g.)

    This variable will contain the version of the package as obtained from the
    ``specfile.in``.  This is the only place the version of the package needs
    to be updated.  In our exmaple case, this would be ``0.1.42``.

  * ``RELEASE_DIST``: empty or ``dl``

    Usually empty.  This is just a suffix for the package release.  This
    variable is intended only for packaging/packager use and not for build
    usage.

  * ``ROOT``: ``/``

    This will be set to the root of the filesystem from which all of the other
    software will be found.  For conventional packages it will be set to
    ``/``.

  * ``PACKAGE_ROOT``: ``/usr/lib/@PACKAGE@``

    This is the root location for any data or code that is specific to the
    package and not intended to be used on the command line.  This is the
    ideal location for programs that are intended to be used as daemons and
    never touched by a user.

    The developer should feel free to place any executable code and data under
    this directory.  This directory is solely for the purpose of this package.

    In our example this would be ``/usr/lib/frobnitz``.

  * ``PACKAGE_SHARE``: ``/usr/share/@PACKAGE@``

    This is one possible path for any data intended to be consumed by the
    user.  The ``renserv.cfg`` files should be installed here.  The usual path
    for this will be ``/usr/share/frobnitz``.

  * ``PACKAGE_ETC``: ``/etc/atelerix/@PACKAGE@``

    Any configuration file data should be stored in this directory.  It will
    map to ``/etc/atelerix/frobnitz``.

  * ``PACKAGE_TMP``: ``/var/tmp/@PACKAGE@``

    This directory is on the /var partition and is for any large temporary
    files that the package may need to create.  You should not expect that
    this directory will contain any files written in a previous run (this
    directory may even be a RAM disk).  Consider also respecting the common
    $TMPDIR environment variable.

  * ``PACKAGE_CACHE``: ``/var/spool/@PACKAGE@``

    This directory is on the /var partition and is for any intermediate work
    required by the application.  If your application uses files to store data
    between runs and needs to have access to data files between runs, then
    this is the appropriate directory to use.

  * ``APACHE_ROOT``: ``/etc/httpd`` (or ``/etc/apache2``)

    This variable is available for placing files that are Apache configuration
    files.  If you are using this macro, the correct location will be selected
    for the host distribution.  In our environment, this will always map to
    ``/etc/httpd/``.  See `Adding an Apache configuration file`_.

  * ``LIBEXEC``: ``/usr/libexec``

    This directory is primarily for the purpose of the daemontools ``start``
    scripts.  See `Adding a daemontools service`_.

  * ``MANDIR``: ``/usr/man``

    This is the base directory for manual pages.  Under this directory should
    be the man1, man3 and such directories.  You will need to make the manX
    subdirectory in your ``Makefile.build``.  See also `Adding a manpage`_.

  * ``BINDIR``:  ``/usr/bin``

    This is for any binaries (or scripts) you wish users to use.  The path
    will be ``/usr/bin`` for conventional packages.

  * ``SBINDIR``:  ``/usr/sbin``

    This is for any binaries (or scripts) you wish only superusers to use.
    The path will be ``/usr/sbin`` for conventional packages.

  * ``ETC``: ``/etc``

    This is the base configuration data directory.  It is usually ``/etc/``.

  * ``VAR``: ``/var``

    The ``/var`` directory.  (FIXME:  Need to add ``PACKAGE_VAR``.)

  * ``SHARE``: ``/usr/share``

    The base directory in which package data is usually stored.  This is,
    customarily, ``/usr/share``.  Please do not use this directory.  See,
    ``PACKAGE_SHARE`` instead.

