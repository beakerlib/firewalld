# NAME

firewalld/main - Manages firewalld configuration, state and cleanup

# DESCRIPTION

firewalld BeakerLib library to aid basic and advanced setup workflows.

# VARIABLES

Below is the list of global variables.

- fwd\_IGNORE\_CONFIG

    Makes fwdSetup not drop existing config nor assert default configuration
    state.

- fwd\_VERIFY\_RPM

    Makes fwdSetup assert integrity of installed files by RPM.

# FUNCTIONS

## fwdSetup

Asserts environment and starts firewalld. Configuration cleanup is attempted
and default state is verified.

    fwdSetup [-n|--no-start] [--backup PATH]

- -n|--no-start

    Do not start service after setup.

- --backup _PATH_

    Additional path to save and restore as part of setup and cleanup.
    Passed to `rlFileBackup`. Can be supplied multiple times.

    No matter if this option is specified, the following paths are
    always backed up:

    `/etc/firewalld/`

    `/etc/sysconfig/firewalld`

    `/etc/sysconfig/network-scripts/`

## fwdCleanup

Restores configuration and service state before fwdSetup was called.

## fwdRestart

Restarts firewalld service.

## fwdResetConfig

Resets config to state after fwdSetup was called and drops runtime firewall config.

    fwdResetConfig [-n|--no-restart]

- -n|--no-restart

    Do not restart firewalld after reseting permanent config.

## fwdSetBackend

Sets firewalld backend to one of \`nftables\` or \`iptables\`. Attempt to
backend when the option is not available will cause Error and return 1.
If backend is not specified, it is set to nftables by default.

    fwdSetBackend [nftables|iptables]

## fwdGetBackend

Returns name of firewalld backend as one of \`nftables\` or \`iptables\`.

    fwdGetBackend

# AUTHORS

- Tomas Dolezal <todoleza@redhat.com>
