#!/usr/bin/env bash

export PYTHONPATH=.

# BEGIN subcommand functions

cmd_topology() {
    echo "Create topology, configuration, and execution files."
    mkdir -p logs traces
    [ -e gen ] && rm -r gen
    [ -e /run/shm/scion-zk ] && rm -r /run/shm/scion-zk
    topology/generator.py "$@"
}

cmd_run() {
    echo "Running the network..."
    supervisor/supervisor.sh reload
    # Supervisor reload causes the domain socket to briefly disappear, which
    # breaks the detection logic in supervisor.sh
    sleep 1
    bash gen/zk_datalog_dirs.sh || exit 1
    supervisor/supervisor.sh quickstart all
}

cmd_stop() {
    echo "Terminating this run of the SCION infrastructure"
    supervisor/supervisor.sh quickstop all
}

cmd_status() {
    supervisor/supervisor.sh status | grep -v RUNNING
    # If all tasks are running, then return 0. Else return 1.
    [ $? -eq 1 ]
    return
}

cmd_test(){
    nosetests "$@"
}

cmd_coverage(){
    set -e
    nosetests --with-cov --cov-report html "$@"
    coverage report
    echo "Coverage report here: file://$PWD/htmlcov/index.html"
}

cmd_lint() {
    set -o pipefail
    flake8 --config flake8.ini "${@:-.}" | sort -t: -k1,1 -k2n,2 -k3n,3
}

cmd_version() {
	cat <<-_EOF
	============================================
	=                  SCION                   =
	=   https://github.com/netsec-ethz/scion   =
	============================================
	_EOF
}

cmd_sock_bld() {
    export LD_LIBRARY_PATH=`pwd`/endhost/sdamp
    make -C endhost
    make -C endhost/sdamp
    make -C endhost/sdamp/test
}

SOCKDIR=endhost/sdamp

cmd_sock_cli() {
    GENDIR=gen/ISD1/AD19/endhost
    ADDR="127.1.19.254"
    APIADDR="127.255.255.254"
    PYTHONPATH=.
    endhost/client_dispatcher $ADDR &
    python3 endhost/dummy.py $GENDIR $ADDR $APIADDR
}

cmd_run_cli() {
    $SOCKDIR/test/client
}

cmd_sock_ser() {
    GENDIR=gen/ISD2/AD26/endhost
    ADDR="127.2.26.254"
    APIADDR="127.255.255.253"
    PYTHONPATH=.
    endhost/server_dispatcher $ADDR &
    python3 endhost/dummy.py $GENDIR $ADDR $APIADDR
}

cmd_run_ser() {
    $SOCKDIR/test/server
}

cmd_help() {
	cmd_version
	echo
	cat <<-_EOF
	Usage:
	    $PROGRAM topology
	        Create topology, configuration, and execution files.
	    $PROGRAM run
	        Run network.
	    $PROGRAM stop
	        Terminate this run of the SCION infrastructure.
	    $PROGRAM status
	        Show all non-running tasks.
	    $PROGRAM test
	        Run all unit tests.
	    $PROGRAM coverage
	        Create a html report with unit test code coverage.
	    $PROGRAM help
	        Show this text.
	    $PROGRAM version
	        Show version information.
	_EOF
}
# END subcommand functions

PROGRAM="${0##*/}"
COMMAND="$1"
shift

case "$COMMAND" in
    coverage|help|lint|run|stop|status|test|topology|version|\
    sock_cli|sock_ser|sock_bld|run_cli|run_ser)
        "cmd_$COMMAND" "$@" ;;
    *)  cmd_help; exit 1 ;;
esac
