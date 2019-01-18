#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/firewalld/Library/main
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

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="firewalld"
PHASE=${PHASE:-Test}

rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport firewalld/main"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

#    # Create file
#    if [[ "$PHASE" =~ "Create" ]]; then
#        rlPhaseStartTest "Create"
#            fileCreate
#        rlPhaseEnd
#    fi

    # Self test
    if [[ "$PHASE" =~ "Test" ]]; then
        rlPhaseStartTest "firewalld Setup and Cleanup"
            rlRun "systemctl stop firewalld"
            rlRun "firewall-cmd --state" 252 "firewalld is not running"
            rlAssertGrep "DefaultZone=public" /etc/firewalld/firewalld.conf

            rlRun "fwdSetup"
            rlRun "firewall-cmd --state" 0 "firewalld is runnig"
            rlRun "ps -ef | grep firewalld | grep debug=10" 0 "debug level is set to 10"

            rlRun "firewall-cmd --set-default-zone work"
            rlRun "firewall-cmd --add-service tftp --permanent"
            rlRun "firewall-cmd --reload"
            rlAssertGrep "DefaultZone=work" /etc/firewalld/firewalld.conf
            rlAssertGrep "tftp" /etc/firewalld/zones/work.xml

            rlRun "fwdCleanup"
            rlRun "firewall-cmd --state" 252 "firewalld is not running"
            rlAssertGrep "DefaultZone=public" /etc/firewalld/firewalld.conf
            rlAssertNotExists /etc/firewalld/zones/work.xml
        rlPhaseEnd

        rlPhaseStartTest "ResetConfig"
            rlRun "fwdSetup"
            rlRun "firewall-cmd --set-default-zone work"
            rlRun "firewall-cmd --add-service tftp --permanent"
            rlRun "firewall-cmd --reload"
            rlAssertGrep "DefaultZone=work" /etc/firewalld/firewalld.conf
            rlAssertGrep "tftp" /etc/firewalld/zones/work.xml

            rlRun "fwdResetConfig"
            #rlRun "fwdRestart" # included in ResetConfig unless --no-restart is given
            rlRun "ps -ef | grep firewalld | grep debug=10" 0 "debug level is set to 10"
            rlAssertGrep "DefaultZone=public" /etc/firewalld/firewalld.conf
            rlAssertNotExists /etc/firewalld/zones/work.xml

            rlRun "firewall-cmd --add-service smtp"
            rlRun "fwdResetConfig -n"
            rlRun "fwdResetConfig --no-restart"
            rlRun "firewall-cmd --query-service smtp"
            rlRun "fwdCleanup"
        rlPhaseEnd
    fi

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
