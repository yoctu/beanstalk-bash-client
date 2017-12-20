#!/bin/bash

# XXX: We should keep the connection open, for example with coproc or a file descriptor
# XXX: add the possibilty
# XXX: Release and bury doesn't work because the connection is not keeped open

SELF="${BASH_SOURCE[0]##*/}"
NAME="${SELF%.sh}"

OPTS="t:H:P:psvxeh"
USAGE="Usage: $SELF [$OPTS]"

HELP="
$USAGE

    Options:
        -t      tube
        -H      Host
        -P      Port
        -s      simulate
        -p      set -o pipefail
        -v      set -v
        -x      set -x
        -e      set -ve
        -h      Help

    Methods
        put
            Put save data to beanstalk
            Syntax: put <pri> <delay> <ttr> <data>
            Examples: $SELF -H localhost -P 11300 -t new put 100 0 100 fuu=uuf
            Return: INSERTED JOBID
            Note: depends on -t TUBE

        peek-ready
            Get the last job of a specific tube
            Syntax: peek-ready
            Examples: $SELF -H localhost -P 11300 -t new peek-ready
            Return: FOUND JOBID BYTES
                    DATA
            Note: depends on -t TUBE

        delete 
            Delete a job
            Syntax: delete JOBID
            Examples: $SELF -H localhost -P 11300 -t new delete JOBID
            Return: DELETED
            Note: Depends on -t TUBE

        stats or list-tubes
            List tubes or give stats of beanstalk
            Syntax: [stats|list-tubes]
            Examples: $SELF -H localhost -P 11300 -t new [stats|list-tubes]
            Return: the data you asked 
            Note: n/a

        watch
            Watch the tube and return the job data, it always removes the jobs after ouputing data
            Syntax: watch
            Examples: $SELF -H localhost -P 11300 -t new watch
            Return: The data of the job
            Note: depends on -t TUBE

        reserve
            Reserve a job, if no job is provided, it will keep looking for a new job
            Syntax: reserve
            Examples: $SELF -H localhost -P 11300 -t new reserve
            Return: RESERVED JOBID BYTES
                    DATA
            Note: depends on -t TUBE

        bury
            Bury a job
            Syntax: bury
            Examples: $SELF H localhost -P 11300 -t new bury jobid priority
            Return: BURIED
            Note: depends on -t TUBE, it doesn't work for the moment, because we don't reserve a job correctly

        release
            Release a job
            Syntax: bury
            Examples: $SELF H localhost -P 11300 -t new release jobid priority delay
            Return: RELEASED
            Note: depends on -t TUBE, it doesn't work for the moment, because we don't reserve a job correctly



            
"

function _quit ()
{
    local retCode="$1" msg="${@:2}"

    echo -e "$msg"
    exit "$retCode"
}

function my_nc ()
{
    nc -w 1 -C "$_host" "$_port"
}

function my_sed ()
{
    sed 's/^[ \t]*//'
}

function my_grep ()
{
    grep -v UNKNOWN_COMMAND
}

function value-checker ()
{
    for value in "$@"
    do
        [[ -z "${!value}" ]] && _quit 2 "Value ($value) is not set! $HELP"
    done
}

function put ()
{
    local priority="$1" delay="$2" ttr="$3" data="$4"

    # check if all values are set
    value-checker priority delay ttr data _tube

    # get custom byte 
    bytes="${#data}"

    # use sed to just have a propper tabulation :)
    echo -e "
        use $_tube\r\n\
        put $priority $delay $ttr $bytes\r\n\
        $data\r\n
    " | my_sed | my_nc | my_grep

}

function peek-ready ()
{

    # check if values are set
    value-checker _tube

    echo -e "
        use $_tube\r\n\
        peek-ready\r\n
    " | my_sed | my_nc | my_grep 
}

function delete ()
{
    local jobid="$1"

    # check if values are set
    value-checker _tube jobid

    echo -e "
        use $_tube\r\n\
        delete $jobid\r\n
    " | my_sed | my_nc | my_grep
}

function bury ()
{
    local jobid="$1" priority="$2"

    # check if values are set
    value-checker _tube jobid priority

    echo -e "
        use $_tube\r\n\
        bury $jobid $priority\r\n
    " | my_sed | my_nc | my_grep
}

function reserve ()
{
    # check if values are set
    value-checker _tube
    
    echo -e "
        use $_tube\r\n\
        reserve\r\n
    " | my_sed | my_nc | my_grep
}

function release ()
{
    local jobid="$1" priority="$2" delay="$3"

    # check if values are set 
    value-checker _tube jobid priority delay
    
    echo -e "
        use $_tube\r\n\
        release $jobid $priority $delay\r\n
    " | my_sed | my_nc | my_grep
}

function watch ()
{
    # check if values are set
    value-checker _tube
    
    # keep connection
    while true
    do
        while read -ra lines 
        do
            # check what the line contains
            if [[ "${lines[0]}" =~ "RESERVED"* ]]
            then
                jobid="${lines[1]}"
            else
                # save data
                data+=" ${lines[@]} "
            fi
        done < <(reserve)    

        if [[ ! -z "$jobid" ]]
        then
            echo -e "$data"
            delete "$jobid" | grep -v DELETE
            unset jobid data
        fi
            
        # sleep a secone my little while
        sleep 1
    done
}

function beanstalk-basic-runner ()
{
    local beanstalk_command="$@"

    echo "$beanstalk_command" | my_sed | my_nc | my_grep
}

while getopts "${OPTS}" arg; do
    case "${arg}" in
        t) _tube="${OPTARG}"                                            ;;
        H) _host="${OPTARG}"                                            ;;
        P) _port="${OPTARG}"                                            ;;
        s) _run="echo"                                                  ;;
        p) set -o pipefail                                              ;;
        v) set -v                                                       ;;
        x) set -x                                                       ;;
        e) set -ve                                                      ;;
        h) _quit 0 "$HELP"                                              ;;
        ?) _quit 1 "Invalid Argument: $USAGE"                           ;;
        *) _quit 1 "$USAGE"                                             ;;
    esac
done
shift $((OPTIND - 1))

value-checker _host _port

_action="$1"

case "$_action" in
    put)        put "$2" "$3" "$4" "$5" "${@:6}"                        ;;
    peek-ready) peek-ready                                              ;;
    list-tubes) beanstalk-basic-runner list-tubes                       ;;
    stats)      beanstalk-basic-runner stats                            ;;
    delete)     delete "$2"                                             ;;
    bury)       bury "$2" "$3"                                          ;;
    reserve)    reserve                                                 ;;
    release)    release "$2" "$3" "$4"                                  ;;
    watch)      watch                                                   ;;
    *)          _quit 2 "Action not Found! $HELP"                       ;;
esac
