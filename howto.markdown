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


### virtual box

clone https://github.com/couchbaselabs/vagrants
it is in /Users/artem/work/vagrants
cd to the appropriate directory (e.g. 4.5.0-beta/ubuntu14) and type `vagrant up`.

export VAGRANT_NODES=2    # if you want fewer than the standard 4 nodes

vagrant ssh node{1…num_nodes} to ssh int`o the box
Once you’re there you can become root via `sudo su`

ssh vagrant@127.0.0.1 -p 2202
password: vagrant

If you want a dev build on Linux you can use the cbdev/* directories and I think it’s a little bit more work (but not much). I haven’t used it myself.

The Support / Manchester guys support this repo well — if you have any questions they are best asked in the Engineering room on HipChat.

Binaries: /opt/couchbase/lib/ns_server/erlang/lib/ns_server/ebin/
Logs: /opt/couchbase/var/lib/couchbase/logs

/opt/couchbase/lib/memcached/ep.so
/opt/couchbase/var/lib/couchbase/memcached.rbac
/opt/couchbase/var/lib/couchbase/logs

shutdown:
vagrant halt node1

vagrant box list
vagrant box remove ubuntu/trusty64

vagrant destroy ubuntu/trusty64

### Toy Build:
http://server.jenkins.couchbase.com/job/watson-toy/

### VPN
http://hub.internal.couchbase.com/confluence/pages/viewpage.action?title=Connecting+to+VPN&spaceKey=cbit
username artem.stemkovski 
password b$2JVuA7cU

### patch erlang
clone from here: https://github.com/couchbasedeps/erlang
branch : couchbase-watson (but might change)

mkdir /Users/artem/work/erl16/install
cd /Users/artem/work/erl16/erlang
 - ./otp_build autoconf
 - ./configure --prefix=/Users/artem/work/erl16/install
 - make
 use script for building erlang
 export INSTALL_DIR=/Users/artem/work/erl16/install
 ~/work/vulcan/tlm/deps/packages/erlang/erlang_unix.sh

./configure --prefix=/Users/artem/work/erl16/install --enable-darwin-64bit  --disable-hipe

#manifest for each build
http://172.23.120.24/builds/latestbuilds/couchbase-server/mad-hatter/

#init new repo
repo init -u git://github.com/couchbase/manifest.git -g all -m branch-master.xml
repo sync

#git look for the certain word in diff
SEARCH=TestBucketsAuth && git log -S$SEARCH --stat -p cbauth_test.go | sed -n "/commit/,/diff/p; /$SEARCH/p"