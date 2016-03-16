### config location for installed couchbase

/Users/artem/Library/Application\ Support/Couchbase/var/lib/couchbase/config

### logs

/Users/artem/Library/Application\ Support/Couchbase/var/lib/couchbase/logs/

### create index on node n0

install/bin/cbq -engine=http://127.0.0.1:9499

cbq> create index test on default(test4) using gsi;

^D - exit

### enable internal settings

http://127.0.0.1:9000/index.html?enableInternalSettings=true

### Jenkins

http://server.jenkins.couchbase.com/

### Review

http://review.couchbase.org

### Bugs

https://issues.couchbase.com

### count active items in cluster:
grep vb_active_curr_items cluster/*/stats.log | awk '{sum+=$3}; END {print sum}'

### count occurences of specific phrase in logs:
grep "failed: connect_timeout" source/*/ns_server.xdcr.log | grep --only-matching ',ns_1.*viber.prod:<' | sort | uniq -c

### diag.log
master_events('ns_1@stnacb10.amunet.edu') =
per_node_processes('ns_1@stnacb10.amunet.edu') =
per_node_babysitter_processes('ns_1@stnacb10.amunet.edu') =
per_node_diag('ns_1@stnacb10.amunet.edu') =

### extract config from diag.log
Starts from per_node_diag('ns_1@stnacb1.amunet.edu') =
Ends with master_events( for next node
