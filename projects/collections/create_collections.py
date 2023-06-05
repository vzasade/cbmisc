#!/usr/bin/env python3

import argparse
import subprocess
import requests
import time
import json
from timeit import default_timer as timer


def run_system_command(command):
    p = subprocess.run(command, capture_output=True)
    if p.returncode != 0:
        exit(1)
    return p.stdout.decode('ascii')


class CollectionCreator:

    def __init__(self, args):
        self.cluster = args.cluster
        self.bucket = args.bucket
        self.scope = args.scope
        self.user = args.user
        self.password = args.password
        self.should_delete_scope = args.delete_scope
        self.delay = args.delay
        self.number = args.number
        self.collection_prefix = args.prefix
        self.num_scopes = args.num_scopes

    def make_curl_command(self, rest_endpoint, post_data=None):
        post_data_list = []
        if post_data is not None:
            post_data_list = ['-d', post_data]
        return ['curl', '-s', '-u', self.user + ':' + self.password, rest_endpoint] + \
            post_data_list

    def make_url(self, rest_endpoint):
        url = self.cluster
        if not url.startswith('http://'):
            url = 'http://' + url
        if not url.endswith('/'):
            url += '/'
        url = url + rest_endpoint
        return url

    def do_get(self, rest_endpoint):
        return requests.request('GET',
                                url=self.make_url(rest_endpoint),
                                auth=(self.user, self.password))

    def do_post(self, rest_endpoint, post_data):
        return requests.request('POST',
                                url=self.make_url(rest_endpoint),
                                data=post_data,
                                auth=(self.user, self.password))

    def do_delete(self, rest_endpoint):
        return requests.request('DELETE',
                                url=self.make_url(rest_endpoint),
                                auth=(self.user, self.password))

    def make_scopes(self):
        for idx in range(0, self.num_scopes):
            name = "{}-{}".format(self.scope, idx)
            start = timer()
            resp = self.do_post('pools/default/buckets/' + self.bucket + '/collections',
                    {'name': name})
            end = timer()
            if resp.status_code == 200:
                print("Created scope '{}' for bucket '{}' in {}".format(name, self.bucket, end - start))
                self.create_collection(idx, name)
            else:
                print("Failed to create scope '{}' for bucket '{}', response: {}".format(
                    name, self.bucket, resp.text))
                exit(8)

    def make_scope(self):
        resp = self.do_post('pools/default/buckets/' + self.bucket + '/collections',
                            {'name': self.scope})
        if resp.status_code == 200:
            return None
        else:
            if resp.status_code == 400 and self.should_delete_scope:
                resp = self.do_delete('pools/default/buckets/' + self.bucket + '/collections/' +
                                      self.scope)
                if resp.status_code != 200:
                    print("could not delete scope {0}; reason: {1}".format(self.scope, resp.text))
                    exit(3)
            else:
                print("could not create scope {0}, response: {1}".format(self.scope, resp.text))
                exit(4)
        resp = self.do_post('pools/default/buckets/' + self.bucket + '/collections',
                            {'name': self.scope})
        if resp.status_code != 200:
            exit(2)
        print("created scope {0}; manifest uid: {1}".format(self.scope, resp.text))
        return None

    def collection_name(self, idx):
        return self.collection_prefix + str(idx)

    def create_collection(self, idx, scope_name=None):
        name = self.collection_name(idx)
        if scope_name is None:
            scope_name = self.scope
        resp = self.do_post('pools/default/buckets/' + self.bucket + '/collections/' + scope_name,
                            {'name': name})
        if resp.status_code != 200:
            print("could not create collection {0}; reason: {1}".format(name, resp.text))
            exit(5)
        print("created collection {0}; manifest uid: {1}".format(name, resp.text))

    def create_collections(self):
        for idx in range(0, self.number):
            self.create_collection(idx)
            to_delay = self.delay / 1000.0
            time.sleep(to_delay)

    def validate_collections(self):
        resp = self.do_get('pools/default/buckets/' + self.bucket + '/collections')
        if resp.status_code != 200:
            print("can't get collections manifest")
            exit(7)
        manifest = json.loads(resp.text)
        scopes = manifest['scopes']
        scope = None
        for s in scopes:
            if s['name'] == self.scope:
                scope = s
        if scope is None:
            print("scope {0} not found in manifest {1}".format(scope, manifest))
            exit(6)
        collections = {}
        for c in scope['collections']:
            collections[c['name']] = c
        for idx in range(0, self.number):
            cname = self.collection_name(idx)
            if collections.get(cname) is None:
                print("collection {0} is missing in manifest {1}".format(cname, manifest))
        print("all collections validated")


parser = argparse.ArgumentParser(description='Mass create collections)')
parser.add_argument('-b', '--bucket', dest='bucket', default='default',
                    help='bucket in which to create collections')
parser.add_argument('-s', '--scope', dest='scope', help='scope', required=True)
parser.add_argument('-S', '--num-scopes', dest='num_scopes', type=int, help='num-scopes', default=0)
parser.add_argument('-c', '--cluster', dest='cluster', help='cluster', required=True)
parser.add_argument('-u', '--user', dest='user', help='user', required=True)
parser.add_argument('-p', '--password', dest='password', help='password', required=True)
parser.add_argument('--prefix', dest='prefix', help='prefix', default='c')
parser.add_argument('--delete-scope', dest='delete_scope', help='should delete scope?', action='store_true')
parser.add_argument('-n', '--number', dest='number', type=int, default=100, help='number')
parser.add_argument('--delay', dest='delay', type=int, default=1000, help='delay in millis')

if __name__ == '__main__':
    args = parser.parse_args()
    creator = CollectionCreator(args)
    if creator.num_scopes:
        creator.make_scopes()
        exit(0)
    creator.make_scope()
    creator.create_collections()
    creator.validate_collections()
