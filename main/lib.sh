#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   lib.sh of /CoreOS/firewalld/Library/main
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
#   library-version = 0.1
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

: <<'=cut'
=pod

=head1 NAME

firewalld/main - Manages firewalld configuration, state and cleanup

=head1 DESCRIPTION

firewalld BeakerLib library to aid basic and advanced setup workflows.

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

: <<'=cut'
=pod

=head1 VARIABLES

Below is the list of global variables.

=over

=item fwd_IGNORE_CONFIG

Makes fwdSetup not drop existing config nor assert default configuration
state.

=back

=cut

__fwdPACKAGES=(
    firewalld
    selinux-policy
    nftables
    libnftnl
    libmnl
    iptables
    )

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Functions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

: <<'=cut'
=pod

=head1 FUNCTIONS

=cut

__fwdStart() {
    #should capture service state by issuing rlService command (consumed by Cleanup)
    rlServiceStart firewalld
    # a blocking command is used
    rlRun "firewall-cmd --state" 0 "firewalld started"
}
__fwdStop() {
    rlServiceStop firewalld
    firewall-cmd --state -q
    [[ $? -ne 252 ]] && rlFail "Could not stop firewalld daemon"
}

__fwdCleanConfig() {
    local fwconfdir
    local ret=0
    for fwconfdir in /etc/firewalld/*/; do
        if [[ -f $fwconfdir/* ]]; then
            rm -f -- $fwconfdir/*
            ret=1
        fi
    done
    return $ret
}

__fwdCleanDebugLog() {
    truncate -s 0 /var/log/firewalld || \
        rlFail "failed to remove debug log data"
}

__fwdSubmitLog() {
    # call me just once, else I'll probably overwrite output by last invocation
    rlFileSubmit /var/log/firewalld firewalld.log
}

__fwdSetDebug() {
    local LEVEL=${1:-10}
    echo "FIREWALLD_ARGS=--debug=$LEVEL" >> /etc/sysconfig/firewalld || \
        rlFail "failed to enable debug flag"
}

: <<'=cut'
=pod

=head2 fwdSetup

Asserts environment and starts firewalld. Configuration cleanup is attempted
and default state is verified.

=cut

fwdSetup() {
    rlFileBackup --namespace fwdlib --clean /etc/firewalld/ /etc/sysconfig/firewalld
    if [[ -z $fwd_IGNORE_CONFIG ]]; then
        __fwdCleanConfig || rlWarn "$fwconfdir was not clean"
        rlRun "rpm -V firewalld" 0 "firewalld configuration is in non-changed default"
    fi
    __fwdSetDebug
    __fwdCleanDebugLog
    rlFileBackup --namespace fwdlib_setup --clean /etc/firewalld/ /etc/sysconfig/firewalld
    __fwdStart
}

: <<'=cut'
=pod

=head2 fwdCleanup

Restores configuration and service state before fwdSetup was called.

=cut

fwdCleanup() {
    rlFileRestore --namespace fwdlib
    __fwdSubmitLog
    __fwdCleanDebugLog
    rlServiceStart firewalld && firewall-cmd --state
    rlServiceRestore firewalld
}

: <<'=cut'
=head2 fwdRestart

Restarts firewalld service.

=cut

fwdRestart() {
    __fwdStart
}

: <<'=cut'
=head2 fwdResetConfig

Resets config to state after fwdSetup was called.

=cut
fwdResetConfig() {
    local NORESTART=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--no-restart)
                NORESTART=true
                shift
                ;;
        esac
    done

    rlFileRestore --namespace fwdlib_setup
    if ! $NORESTART ; then
        __fwdStart
    fi
}


# TODO: verify a rule is present in system firewall configuration
# TODO: abstract over iptables & nftables (using json output)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Execution
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#: <<'=cut'
#=pod
#
#=head1 EXECUTION
#
#This library supports direct execution. When run as a task, phases
#provided in the PHASE environment variable will be executed.
#Supported phases are:
#
#=over
#
#=item Create
#
#Create a new empty file. Use FILENAME to provide the desired file
#name. By default 'foo' is created in the current directory.
#
#=item Test
#
#Run the self test suite.
#
#=back
#
#=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Verification
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   This is a verification callback which will be called by
#   rlImport after sourcing the library to make sure everything is
#   all right. It makes sense to perform a basic sanity test and
#   check that all required packages are installed. The function
#   should return 0 only when the library is ready to serve.

fwdLibraryLoaded() {
    if rpm=$(rpm -q ${__fwdPACKAGES[0]}); then
        sepol=$(rpm -q selinux-policy)
        rlLogInfo "Library firewalld/main running with $rpm on $sepol in $(getenforce) mode"

        for pkg in ${__fwdPACKAGES[@]} kernel-$(uname -r); do
            rlAssertRpm $pkg
        done

        return 0
    else
        rlLogError "firewalld not installed"
        return 1
    fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Authors
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

: <<'=cut'
=pod

=head1 AUTHORS

=over

=item *

Tomas Dolezal <todoleza@redhat.com>

=back

=cut