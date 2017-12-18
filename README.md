# beanstalk-bash-client

Usage: [beanstalk-client.sh](https://github.com/yoctu/beanstalk-bash-client/blob/master/beanstalk-client.sh) `[t:H:P:psvxeh]`

```
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
            Examples: beanstalk-client.sh -H localhost -P 11300 -t new put 100 0 100 fuu=uuf
            Return: INSERTED JOBID
            Note: depends on -t TUBE

        peek-ready
            Get the last job of a specific tube
            Syntax: peek-ready
            Examples: beanstalk-client.sh -H localhost -P 11300 -t new peek-ready
            Return: FOUND JOBID BYTES
                    DATA
            Note: depends on -t TUBE

        delete 
            Delete a job
            Syntax: delete JOBID
            Examples: beanstalk-client.sh -H localhost -P 11300 -t new delete JOBID
            Return: DELETED
            Note: Depends on -t TUBE

        stats or list-tubes
            List tubes or give stats of beanstalk
            Syntax: [stats|list-tubes]
            Examples: beanstalk-client.sh -H localhost -P 11300 -t new [stats|list-tubes]
            Return: the data you asked 
            Note: n/a

        watch
            Watch the tube and return the job data, it always removes the jobs after ouputing data
            Syntax: watch
            Examples: beanstalk-client.sh -H localhost -P 11300 -t new watch
            Return: The data of the job
            Note: depends on -t TUBE

        reserve
            Reserve a job, if no job is provided, it will keep looking for a new job
            Syntax: reserve
            Examples: beanstalk-client.sh -H localhost -P 11300 -t new reserve
            Return: RESERVED JOBID BYTES
                    DATA
            Note: depends on -t TUBE

        bury
            Bury a job
            Syntax: bury
            Examples: beanstalk-client.sh H localhost -P 11300 -t new bury jobid priority
            Return: BURIED
            Note: depends on -t TUBE, it doesn't work for the moment, because we don't reserve a job correctly

        release
            Release a job
            Syntax: bury
            Examples: beanstalk-client.sh H localhost -P 11300 -t new release jobid priority delay
            Return: RELEASED
            Note: depends on -t TUBE, it doesn't work for the moment, because we don't reserve a job correctly

```
