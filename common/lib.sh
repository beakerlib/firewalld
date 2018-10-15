#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   lib.sh of /CoreOS/firewalld/Library/common
#   Description: Manages firewalld configuration, restoration and other stuff
#   Author: Tomas Dolezal <todoleza@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   library-prefix = fwd
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 NAME

firewalld/common - Manages firewalld configuration, state and cleanup

=head1 DESCRIPTION

--none--
=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#true <<'=cut'
#=pod
#
#=head1 VARIABLES
#
#Below is the list of global variables. When writing a new library,
#please make sure that all global variables start with the library
#prefix to prevent collisions with other libraries.
#
#=over
#
#=item fileFILENAME
#
#Default file name to be used when no provided ('foo').
#
#=back
#
#=cut

PACKAGES=(
    firewalld
    selinux-policy
    nftables
    libnftnl
    libmnl
    )

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Functions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 FUNCTIONS

=head2 fileCreate

Create a new file, name it accordingly and make sure (assert) that
the file is successfully created.

    fileCreate [filename]

=over

=item filename

Name for the newly created file. Optionally the filename can be
provided in the FILENAME environment variable. When no file name
is given 'foo' is used by default.

=back

Returns 0 when the file is successfully created, non-zero otherwise.

=cut


__fwdStart() {
    true
}

# TODO: clean and reset configuration
fwdResetConfig() {
    true
}

# TODO: call reset configuration after backup to own namespace
fwdSetup() {
    rlFileBackup --clean /etc/firewalld/ /etc/sysconfig/firewalld
    for fwconfdir in /etc/firewalld/*/; do
        if [[ -f $fwconfdir/* ]]; then
            rm -f -- $fwconfdir/*
            rlWarn "$fwconfdir was not clean"
        fi
    done
    rlRun "rpm -V firewalld" 0 "firewalld configuration is default"
    rlServiceStart firewalld
    # a blocking command is used
    rlRun "firewall-cmd --state" 0 "firewalld running"
}

# TODO: clean/restore state of configuration before library initialization
# TODO: restore service status
fwdCleanup() {
    rlFileRestore
    rlServiceStart firewalld && firewall-cmd --state
    rlServiceRestore firewalld
}

# TODO: verify a rule is present in system firewall configuration
# TODO: abstract over iptables & nftables (using json output)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Execution
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 EXECUTION

This library supports direct execution. When run as a task, phases
provided in the PHASE environment variable will be executed.
Supported phases are:

=over

=item Create

Create a new empty file. Use FILENAME to provide the desired file
name. By default 'foo' is created in the current directory.

=item Test

Run the self test suite.

=back

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Verification
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   This is a verification callback which will be called by
#   rlImport after sourcing the library to make sure everything is
#   all right. It makes sense to perform a basic sanity test and
#   check that all required packages are installed. The function
#   should return 0 only when the library is ready to serve.

# TODO: check components versions, assert them
# TODO: make sure default configuration is being used, or prepare it cleaned up (conditionally don't)
# TODO: check system firewall settings in case fwd is off, prior starting the service, log it but drop it

fwdLibraryLoaded() {
    if rpm=$(rpm -q ${PACKAGES[0]}); then
        sepol=$(rpm -q selinux-policy)
        rlLogDebug "Library firewalld/common running with $rpm on $sepol in $(getenforce) mode"
        return 0
    else
        rlLogError "Package  not installed"
        return 1
    fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Authors
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 AUTHORS

=over

=item *

Tomas Dolezal <todoleza@redhat.com>

=back

=cut
