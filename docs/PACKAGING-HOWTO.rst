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
This is atelerix, a build/packaging tool that assists in the routine
management of a version-controlled code base.  It provides:

  #. simple search-and-replace code generation
  #. predictable and repeatable RPM generation
  #. integration with an Open Build Service (OBS) instance

It is best suited for packages that are largely composed of scripts,
configuration files and other simple interdependent utilities. The
Makefile provides support generated manpages and easy placement of files in
predictable locations in the filesystem.


.. contents:: Table of Contents
   :depth: 5

Quickstart
----------

This directory can be used as a template for any other package. See
the section `Creating a new package (using svn)`_ for details on how to adapt
your own project to use atelerix.

How to build
++++++++++++

In order to build an RPM, you should only need a base system, ``rpmbuild``,
``python`` and GNU ``make``. ::

  make testrpm

In order to build the RPM from your version control system (probably
subversion), you should have the ``svn`` command line client which has been
configured to use the central repository (See `Using alternate version control
systems`_)::

  make rpm

In order to upload a package to the Open Build Service (OBS), you will
need the ``osc`` command line client which has been configured in your
environment with your credentials for connecting to the OBS.  The credentials
found in ``~/.oscrc`` will be used::

  make obs

That's the crash course!


Build process
+++++++++++++

For a bit more detail, here's what is happening when you build the
``rpm`` target.  From the example directory, when you type ``make rpm``,
the following steps will occur.:

  #. This will generate a correctly named specfile (i.e. ``atelerix.spec``
     from ``specfile.in``.

  #. Connect to the VCS (svn, git or hg) and download a tarball of the source
     distribution, creating, e.g. ``atelerix-0.2.14.tar.gz``.

  #. Execute ``rpmbuild`` against the generated specfile.

  #. Produce an RPM (FHS-style, with minor modifications) and SRPM.

  #. Clean up any intermediate work and directories.

  #. Leave the RPMs, SRPM, tarball and specfile in the ./dist/ directory.

If you want to restore a pristine directory, simply type ``make distclean`` to
remove the ./dist/ directory.  This is safe, since the package can always be
rebuilt directly from the version control system.


Overview
--------

For small collections of scripts, or even compiled code, this Makefile-driven
system is simpler than a similar toolchain written in autotools.  It is for
this reason that we wrote this.

Goals of the atelerix system
++++++++++++++++++++++++++++

  * Minimize the time between developer code change and potential deployment.
    (Works with Open Build Service here.)
 
  * Allow easy support of predictable versioning of each piece of software.
 
  * Provide guaranteed reproducibility of build for individual packages.

  * Provide well-packaged, consistent RPMS to operations to ease the burden of
    software management.

  * Provide tight integration with a version control system (subversion) so
    that packages can be built directly from the repository.

  * Provide integration features with Open Build Service (OBS_), a complete
    software platform (re)building tool.  See also InternalOBS_.

Big picture of usage
++++++++++++++++++++

The ``Makefile`` itself should remain the same across all packages.
Instructions for macro replacement and final installation can be found in the
``Makefile.build``.  Used together with ``specfile.in`` by the
developer/packager to capture all code, data and configuration files that need
to be shipped with the RPM.
 


Using the template
------------------

Creating a new package (using svn)
++++++++++++++++++++++++++++++++++

  #. Copy the required template files to a new directory (assuming new
     package called frobnitz and you are using svn). ::

       mkdir frobnitz/{trunk,branches,tags}
       svn add frobnitz
       svn commit frobnitz -m 'add new project frobnitz'
       cd example-packaging/trunk
       cp Makefile Makefile.build specfile.in ../../frobnitz/trunk
       # copy this if your project includes Python code
       cp -p setup.py.in ../../frobnitz/trunk
       # copy these two if your package includes services
       cp pkg/renserv.cfg.in pkg/start.in ../../frobnitz/trunk
       cd ../../frobnitz/trunk
       # don't forget to add some text to these! empty docs help no one
       touch README RELEASE-NOTES
       svn add *

  #. Modify the ``specfile.in`` to change the Name and Version.  You should
     also modify the Summary field and the %changelog (which must be
     in chronological order, newest stuff at the top).

  #. Build the package with ``make testrpm``.  If that succeeds, then you
     have a package.

  #. Commit the work with ``svn commit -m 'initial commit of frobnitz'``.

  #. Build the package out of subversion with ``make rpm``.

  #. Find the package in ``./dist/``.

  #. Toss the package into OBS_ with ``make obs``.



Features of the example package
+++++++++++++++++++++++++++++++

  * The ``Makefile`` provides Renesys standard (not far from FHS) locations
    for configuration directories, static data, a cache directory, available
    integration for daemon services, and documentation.

  * The example package includes a ``start.in`` and a ``renserv.cfg.in``
    file. The ``renserv.cfg.in`` file defines the environment in which (and
    user under which) you wish your process to run. If your program can (or
    should) be controlled by environment variables, put them (documented)
    into this file. Our operations group usually copies this file into their
    configuration management system for a given service.

  * The ``start.in`` file contains the startup instructions for your daemon.
    It is very likely that the final command in this script will be
    something like:

      ``exec -a ${ARGV0:-@PACKAGE@} @PACKAGE_ROOT@/daemonic-utility``

    All of the environment variables specified in ``renserv.cfg`` may be
    already set, but should be checked and have defaults set here (or in the
    eventual daemon).

    Of course, this ``start.in`` can do anything you want it to do, and it
    need not be shell.

    On the target host in question, ``start.in`` will turn into something like
    ``/usr/libexec/start-frobnitz-0.3.17`` or similar.

  * The packaging style supports the usage of POD for writing manpages.  This
    could be extended to support other input formats.

  * The ``Makefile`` supports connecting to an instance of the Open Build
    Service (OBS) to submit new versions of packages.  The OBS system used
    depends entirely on your working environment (i.e. your ~/.oscrc).



Examples
--------
Below are a few examples for how to add certain kinds of content to a package.

Adding a configuration file
+++++++++++++++++++++++++++

If any of your scripts needs a configuration file (separate from configuration
data passed via environment variables), you should use the ``@PACKAGE_ETC@``
macro and directory.  Here's an example script called ``frobnitz`` which will
need to read a configuration file.

  #. Make your program name ``frobnitz.in``.

  #. Add ``frobnitz`` to ``BUILT_FILES`` in ``Makefile.build``. ::

       BUILT_FILES := frobnitz

  #. Create your configuration file ``main.conf`` and add to the repository.

  #. Install the configuration file ``main.conf`` in the install target. ::

       install:
           mkdir -p $(DESTDIR)$(PACKAGE_ETC)
           install -m 0644 main.conf $(DESTDIR)$(PACKAGE_ETC)

  #. After the package is installed, the configuration file will live here: ::

     /etc/renesys/frobnitz/
     /etc/renesys/frobnitz/main.conf

  #. Therefore, add the configuration file and directory to ``specfile.in``.  ::

     %dir                   @PACKAGE_ETC@
     %config(noreplace)     @PACKAGE_ETC@/frobnitz.conf

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

       @MANDIR@/man1/proggie.1*


Adding a sample Apache configuration file
+++++++++++++++++++++++++++++++++++++++++

The below instructions assume that your proggie is going to be installed in your
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


Adding a renserv (daemontools) service
++++++++++++++++++++++++++++++++++++++

  #. Add a file called ``renserv.cfg.in`` to your package.

  #. Add, at absolute least, the first two lines, which define the software
     (and version, if you must) and the user as which the software will
     run. ::

       SERVICE=@PACKAGE@
       USER=gradus

  #. Add a ``start.in`` file which calls your daemon software. ::

       #! /bin/bash
       exec @PACKAGE_ROOT@/your-daemon

  #. Modify your ``Makefile.build`` install target to look like this: ::

       mkdir -p $(DESTDIR)$(PACKAGE_SHARE)
       install -m 0644 renserv.cfg $(DESTDIR)$(PACKAGE_SHARE)
       #
       # -- install the start files for the daemontools services
       #
       mkdir -p $(DESTDIR)$(LIBEXEC)
       install -m 0755 start $(DESTDIR)$(LIBEXEC)/start-$(PACKAGE)
       install -m 0755 start $(DESTDIR)$(LIBEXEC)/start-$(PACKAGE)-$(VERSION)

Here's a brief summary of how the ``start.in`` and ``renserv.cfg.in`` files
get used to run your service.

  #. You write``start.in`` and ``renserv.cfg.in``.

  #. At build time, these are created as (for example),
     ``/usr/share/frobnitz/renserv.cfg`` and ``/usr/libexec/start-frobnitz``.

  #. You ask to have the software deployed and the service started.

  #. Ops installs the package.

  #. Ops copies ``/usr/share/frobnitz/renserv.cfg`` into
     ``/etc/renesys/services/frobnitz`` and adjusts the variables as
     necessary for production.  (They probably use their configuration
     management system, DACS, to do this.)

  #. Ops runs ``renserv start frobnitz``.

  #. The ``supervise`` finds the variables, as specified by ops in the
     ``renserv.cfg`` configuration file, puts them into the process
     environment and executes your ``start`` script.  (Some details
     elided.)

  #. Your ``start`` script, therefore will find configurables in the process
     environment.


Testing to see if a package builds successfully
+++++++++++++++++++++++++++++++++++++++++++++++

You have finished editing your code, you have modified your ``specfile.in``
and your ``Makefile.build`` ``install`` target and you think the package
should build.  How do you test? ::

  make testrpm

You will see a series of commands excute, and if the job  exits successfully,
you will find several files in ./dist/, which will include (assuming the
package is named frobnitz-0.1.42:::

  dist/frobnitz-0.1.42.tar.gz
  dist/frobnitz-0.1.42-1.src.rpm
  dist/frobnitz-0.1.42-1.noarch.rpm
  dist/frobnitz.spec


Listing the contents of a generated package
+++++++++++++++++++++++++++++++++++++++++++

Supposing you have generated a package and you wish to see the list of files
that have been included for distribution (and eventual installation on the end
system).  The ``rpm`` command operates not only on the installed software base
on the system you are working on, but also operates on RPM files on disk, so
you can point ``rpm`` at your generated package and have it show you the
contents (these two commands produce the same result):::

  rpm --query --list --package dist/frobnitz-0.1.42-1.noarch.rpm
  rpm -qlp dist/frobnitz-0.1.42-1.noarch.rpm

The result of the above command would be something like the following:::

  /usr/lib/frobnitz
  /usr/lib/frobnitz/script.py
  /usr/libexec/start-frobnitz
  /usr/libexec/start-frobnitz-0.1.42
  /usr/share/doc/packages/frobnitz
  /usr/share/doc/packages/frobnitz/README
  /usr/share/doc/packages/frobnitz/RELEASE-NOTES
  /usr/share/frobnitz
  /usr/share/frobnitz/renserv.cfg

Supposing you need a bit more detail about the contents of the package:::

  rpm --query --list --verbose --package dist/frobnitz-0.1.42-1.noarch.rpm
  rpm -qlvp dist/frobnitz-0.1.42-1.noarch.rpm

The results for increased verbosity:::

  drwxr-xr-x    2 root    root                0 Apr  9 02:50 /usr/lib/frobnitz
  -rwxr-xr-x    1 root    root               58 Apr  9 02:50 /usr/lib/frobnitz/script.py
  -rwxr-xr-x    1 root    root              433 Apr  9 02:50 /usr/libexec/start-frobnitz
  -rwxr-xr-x    1 root    root              433 Apr  9 02:50 /usr/libexec/start-frobnitz-0.1.42
  drwxr-xr-x    2 root    root                0 Apr  9 02:50 /usr/share/doc/packages/frobnitz
  -rw-r--r--    1 root    root                0 Apr  9 01:57 /usr/share/doc/packages/frobnitz/README
  -rw-r--r--    1 root    root                0 Apr  9 01:57 /usr/share/doc/packages/frobnitz/RELEASE-NOTES
  drwxr-xr-x    2 root    root                0 Apr  9 02:50 /usr/share/frobnitz
  -rw-r--r--    1 root    root              194 Apr  9 02:50 /usr/share/frobnitz/renserv.cfg


Increasing the version number of the software
+++++++++++++++++++++++++++++++++++++++++++++

After you are able to successfully build the software out of your working
directory, using ``make testrpm``, you will probably commit the software.  The
next step is to bump the version of the software.  Minimally, modify the
Version line in the ``specfile.in``.  This is most often the second line of
the file. ::

  head -n 2 specfile.in
  Name:           frobnitz
  Version:        0.1.42

It is good behaviour (though not required) to put in a reason for the package
change in the %changelog. ::

  %changelog
  * Tue Mar 25 2014 Martin A. Brown <mabrown@renesys.com> [0.1.42-1]
    - adding support for mastication agents
    - improving efficiency of memory usage for >100k turnips
    - correcting typographical errors in punctuation

At this point, you should run ``make testrpm`` again to make sure that the
package builds cleanly after your minor ``specfile.in`` changes.  If that
succeeds, then, it is time to commit your outstanding work to the version
control system.


Adding a version control tag
++++++++++++++++++++++++++++

The default version control system at Renesys is ``svn`` (subversion).  A
software tag is a way to take a snapshot of the state of all files in a given
tree at a particular time.  A common convention is to name the tag after the
software version.

  #. Set the version number as described in `Increasing the version number
     of the software`_.

  #. Move into the ./trunk/ directory.

  #. Commit any pending changes. (e.g. ``svn commit``)

  #. Check that you have no pending work. (e.g. ``svn status``)

  #. Run ``make tag``.

This will create a new tag in the version control system that will immortalize
(well, depending on your VCS) the current state of the tree.  You will be able
in the future to rebuild that version of the software (see below).


Building the package from the version control system
++++++++++++++++++++++++++++++++++++++++++++++++++++

This is trivial, and is part of the major point of atelerix.

  #. ``cd tags/frobnitz-0.1.42``

  #. ``make rpm`` (See below.)


Submitting a package to OBS
+++++++++++++++++++++++++++

After creating a package, you will want to put it into the Open Build
Service (InternalOBS_) instance that Renesys runs internally.  From there, the
package will get rebuilt for all platforms and architectures that we are
supporting.

Assuming you have created a tag for your software, and you wish to distribute
that internally (to the ``dev:internal`` repository, let's say):

  #. ``cd tags/frobnitz-0.1.42``

  #. ``make obsdev``

The RPM will be rebuilt directly from the version control system. The
resulting package will be sent to the Open Build Service instance.

You may determine whether the package goes to the ``dev:internal`` project
``home:$USER`` (where ``$USER`` comes from your ``~/.oscrc`` file).

  * ``make obs`` to send it to ``home:$USER``

  * ``make obsdev`` to send it to ``dev:internal``

Supposing you haven't created a tag yet, and you still want to send the
package to the OBS, but maybe just for your own testing:

  #. ``cd trunk``

  #. ``make testobs``

The RPM will be rebuilt from the current working directory, and
uploaded to the OBS project ``home:$USER``


Using alternate version control systems
+++++++++++++++++++++++++++++++++++++++

This system supports the use of alternate version control systems.  Since
``git`` supports bidirectional communication with the ``git-svn`` tool, there
is some (incomplete) support for interacting with the Renesys subversion
repository and packaging system with ``git``.  If you have questions about
this, just ask--several people are using these tools.


Different files and what they do
--------------------------------

The primary files involved in the atelerix system are listed below
along with some notes about what they do.

.. _Makefile:

  * Makefile (required)

    The instructions which attempt to ease the management of package-building,
    the versioning and tagging and upload to the Open build service.  This
    file should not be changed.

.. _Makefile.build:

  * Makefile.build (required)

    The package-specific instructions which include, minimally, an ``install``
    target which creates the files in the correct locations for the
    ``specfile.in`` to find.  There are other optional targets available in
    this file: the ``build`` target for building software (macro replacements,
    for example), the ``tests`` target for running a test suite and the
    ``docs`` target for generating documentation.

.. _specfile.in:

  * specfile.in (required)

    An RPM specification file (a.k.a. specfile) which contains the name and
    version of the package, the %files section which identifies where to
    install files on the end system and a %changelog section.  This file
    contains metadata about the package for both build time and software
    installation time.

.. _README:

  * README (optional)

    The README is documentation that normally goes along with the package and
    should include the name and purpose of the software.  You can put docs
    here, or you can point to more detailed documentation that is elsewhere
    (HTML docs, manpages and so forth).

.. _RELEASE-NOTES:

  * RELEASE-NOTES (optional)

    This file is primarily used to communicate to operations any changes,
    corrections or even step-by-step instructions required at software
    installation and upgrade time.  This can be hints, tips or even a detailed
    guide for what to do at deployment.

.. _renserv.cfg.in:

  * renserv.cfg.in (optional)

    This (optional) file is used in conjunction with ``start`` (`start.in`_)
    when running a daemonized service (a supervised or daemontools service).
    The file should contain all of the environment variable configurables that
    you would like to have available for the running service (and a little bit
    of an explanation of each).

.. _start.in:

  * start.in (optional)

    This file is an executable file (script?) which is started by the
    daemontools supervise process.  Any variables that have been set during
    deployment of the ``renserv.cfg`` (`renserv.cfg.in`_) config file (which
    defines the service) will be available in the process environment of
    ``start``.  If this script calls any other program, it should end with an
    ``exec program`` in order to avoid process supervision issues.


Available ``Makefile`` targets
------------------------------

The default target is the first target, ``build``.

  * ``build``

    The ``build`` target is passed through directly to ``Makefile.build``.

    Since this system isn't targetted for traditional C-style software, it
    performs replacements of macros in a very similar fashion to autotools,
    but is far simpler to deal with.  For example, if you have a file
    (``start.in``) which is used to generate a ``start`` file, the
    transformation of ``@PACKAGE@`` into ``frobnitz`` is made with this
    target.

    The ``Makefile`` calls the ``Makefile.build`` for this target.  The
    ``Makefile.build`` file must include a ``build`` target.  The default
    ``build`` target looks like this: ::

        build: $(SUBDATA) $(BUILT_FILES) $(MANPAGES)

    This single line means that any files in $(BUILT_FILES) or $(MANPAGES)
    will be built when the ``build`` target is called.

  * ``install``

    The ``install`` target is passed through directly to ``Makefile.build``.

    This is the most important target for the developer.  The developer is in
    complete control of the locations for the software.  See the section on
    the available `Macros available at build time`_ to choose which directory
    may be appropriate for a given file (config file, data or code).

  * ``docs``

    The ``docs`` target is handled by ``Makefile.build``.

  * ``tests``

    The ``tests`` target is handled by ``Makefile.build``.

  * ``vars``

    The ``vars`` target simply produces the list of the Makefile-supplied
    variables (macros) and prints them out.  Good for diagnostics.

  * ``srpm``

    Build the Source RPM only.  If successful, the packages will be found
    under ./dist/.

  * ``rpm``

    Build the binary (RPM) and source (SRPM) packages from the version control
    system.  The resulting, successfully built package will be found under
    ./dist/.

  * ``testrpm``

    The ``testrpm`` target will build an RPM straight out of the working
    directory.  This allows testing of builds before committing any code to
    the version control system.

  * ``tag``

    The ``tag`` target attempts to add a version control tag for the current
    package and version of the software.  This target respects the setting of
    ``SCM_TYPE`` (which defaults to ``svn``).  Assuming our example software
    of ``frobnitz-0.1.42``, the software will create a version control tag
    called ``frobnitz-0.1.42`` for the current version.  It will fail if
    the tag already exists.

  * ``obs``

    The ``obs`` target will build the RPM out of the version control system
    and then try to upload the resulting specfile and tarball to the OBS
    system. By default, it uses your personal project, ``home:$USER``,
    although this is controllable with the OBSPROJECT Makefile variable. ::

       make obs OBSPROJECT=dev:internal

    (or just use ``make obsdev``).

    As a side effect of the attempted upload, a new project directory will be
    created in the OBS if no package is currently known in the working
    project.  This allows the usage of the ``obs`` target regardless of
    whether the package is a new submission or a revision to an existing
    package.

  * ``obsdev``, ``obs-dev``

    Shortcut for ``make obs OBSPROJECT=dev:internal``.

  * ``testobs``

    The ``testobs`` target is exactly the same as the ``obs`` target, except
    that the RPM to be uploaded will be built from the working directory.  (In
    short, ``testrpm`` will be called to build the RPM, and then the ``obs``
    target will be called.)

    Shortcut for ``make obs SCM_TYPE=test OBSPROJECT=dev:internal``.


Macros available at build time
------------------------------

The macros are available in both ``specfile.in`` and also in
``Makefile.build``.  The macros have a slightly different syntax in each of
these files.  In all of the below, imagine a package called
``frobnitz-0.1.42``.

Using the macros:
+++++++++++++++++

Suppose you want to refer to the ``PACKAGE_ROOT`` macro in your code so that
you can have ``/usr/lib/frobnitz`` inline in your code.

  * In ``Makefile.build``, you should use the Makefile variable ``$(PACKAGE_ROOT)``.

  * In ``specfile.in`` and any ``*.in`` files (a.k.a. ``$(BUILT_FILES)``), use
    the replacement string/macro with at signs: ``@PACKAGE_ROOT@``.

Available macros:
+++++++++++++++++

  * ``PACKAGE``: ``frobnitz`` (e.g.)

    This variable will contain the name of the package as obtained from the
    ``specfile.in``.  This is the only place the name of the package needs to
    be entered.  In our example case, this would be ``frobnitz``.

  * ``VERSION``:  ``0.1.42`` (e.g.)

    This variable will contain the version of the package as obtained from the
    ``specfile.in``.  This is the only place the version of the package needs
    to be updated.  In our example case, this would be ``0.1.42``.

  * ``MAJOR_VERSION``: ``0``

  * ``MAJOR_PACKAGE``: ``frobnitz-0``

  * ``MINOR_VERSION``: ``0.1``

  * ``MINOR_PACKAGE``: ``frobnitz-0.1``

  * ``PACKAGE_ROOT``: ``/usr/lib/@PACKAGE@``

    This is the root location for any data or code that is specific to the
    package and not intended to be used on the command line.  This is the
    ideal location for programs that are intended to be used as daemons and
    never touched by a user.

    The developer should feel free to place any executable code and data under
    this directory.  This directory is solely for the purpose of this package.

    In our example this would be ``/usr/lib/frobnitz``.

  * ``PACKAGE_SHARE``: ``/usr/share/@PACKAGE@``

    This is the best choice of path for any static package data.  By
    convention, we put our sample ``renserv.cfg`` files here, too.
    The usual path for this will be ``/usr/share/frobnitz``.  The package
    has complete control of everything under this directory.

  * ``PACKAGE_ETC``: ``/etc/renesys/@PACKAGE@``

    Any configuration file data should be stored in this directory.  It will
    map to ``/etc/renesys/frobnitz``.

  * ``PACKAGE_CACHE``: ``/var/cache/@PACKAGE@``

    This directory is on the /var partition and is for any intermediate work
    required by the application.  If your application uses files to store data
    between runs and needs to have access to data files between runs, then
    this is the appropriate directory to use.

  * ``PACKAGE_SPOOL``: ``/var/spool/@PACKAGE@``

    This directory is on the /var partition and is for any intermediate work
    required by the application.  If your application uses files to store data
    between runs and needs to have access to data files between runs, then
    this is the appropriate directory to use.

  * ``APACHE_ROOT``: ``/etc/httpd`` (or ``/etc/apache2``)

    This variable is available for placing files that are Apache configuration
    files.  If you are using this macro, the correct location will be selected
    for the host distribution.  In our environment, this will always map to
    ``/etc/httpd/``.  See `Adding a sample Apache configuration file`_.

  * ``LIBEXEC``: ``/usr/libexec``

    This directory is primarily for the purpose of the daemontools ``start``
    scripts.  See `Adding a renserv (daemontools) service`_.

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

    The ``/var`` directory.

  * ``SHARE``: ``/usr/share``

    The base directory in which package data is usually stored.  This is,
    customarily, ``/usr/share``.  Please do not use this directory.  See,
    ``PACKAGE_SHARE`` instead.

  * ``PACKAGE_TMP``: ``/var/tmp/@PACKAGE@``

    This directory is on the /var partition and is for any large temporary
    files that the package may need to create.  You should not expect that
    this directory will contain any files written in a previous run (this
    directory may even be a RAM disk).  Consider also respecting the common
    $TMPDIR environment variable.

    (Deprecated.  We have run afoul of the pruning strategies of
    ``tmpwatch`` with using this directory as a package-owned directory.
    Better would be to have a short-running program use the $TMPDIR
    environment variable, use /tmp/ or /var/tmp with safe-file and directory
    handling or, perhaps the best option, use @PACKAGE_CACHE@.)

  * ``ROOT``: ``/``

    This will be set to the root of the filesystem from which all of the other
    software will be found.  It will be set to the empty string, so that
    everything will be installed relative to the Unix root directory ``/``.


Sample build output
-------------------

If you were to try ``make testrpm``, you should see output that looks like
this:

.. include:: sample-build.txt
  :literal:


References
----------
  * `OBS <http://openbuildservice.org/>`_
  * `InternalOBS <https://staff.renesys.com/twiki/bin/view/Renesys/InternalOBS>`_
