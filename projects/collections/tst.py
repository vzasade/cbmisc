#!/usr/bin/env python

from couchbase.cluster import Cluster, PasswordAuthenticator
from couchbase.exceptions import NotFoundError

def tst(cb, key):
    try:
        cb.remove(key)
    except NotFoundError:
        print ('Nothing to delete')

    rv = cb.upsert(key, {'hello': 'world'})
    cas = rv.cas
    print(rv)

    item = cb.get(key)
    print(item)

cluster = Cluster('couchbase://localhost:12000')
cluster.authenticate(PasswordAuthenticator('Administrator', 'asdasd'))
cb = cluster.open_bucket('test')

tst(cb, 'blah')
