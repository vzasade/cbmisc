# config location for installed couchbase

/Users/artem/Library/Application\ Support/Couchbase/var/lib/couchbase/config

# logs

/Users/artem/Library/Application\ Support/Couchbase/var/lib/couchbase/logs/

# create index on node n0

install/bin/cbq -engine=http://127.0.0.1:9499

cbq> create index test on default(test4) using gsi;

^D - exit

# enable internal settings

http://127.0.0.1:9000/index.html?enableInternalSettings=true