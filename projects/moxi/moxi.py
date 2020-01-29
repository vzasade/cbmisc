#!/usr/bin/env python
import sys
sys.path = ['/Users/artem/work/spock/testrunner/lib']+sys.path

from mc_bin_client import MemcachedClient, MemcachedError
from mc_ascii_client import MemcachedAsciiClient

def main_pre():
    client = MemcachedClient('127.0.0.1', 12001, 60000)
    print('binary on default')
    print(client.get('aa'))

    client = MemcachedClient('127.0.0.1', 12001, 60000)
    client.sasl_auth_plain('locked','asdasd')
    #client.bucket_select('locked')
    print('binary on locked')
    print(client.get('aa'))

    client = MemcachedClient('127.0.0.1', 1234, 60000)
    print('binary on unlocked')
    print(client.get('aa'))

    client = MemcachedAsciiClient('127.0.0.1', 12001, 60000)
    print('ascii on default')
    print(client.get('aa'))

    client = MemcachedAsciiClient('127.0.0.1', 1234, 60000)
    print('ascii on unlocked')
    print(client.get('aa'))

    print("moxi.")

def main_dedicated_moxi():
    client = MemcachedClient('127.0.0.1', 1234, 60000)
    print('binary on test')
    print(client.get('aa'))

    client = MemcachedAsciiClient('127.0.0.1', 1234, 60000)
    print('ascii on unlocked')
    print(client.get('aa'))

def main_doesnt_work():
    client = MemcachedClient('127.0.0.1', 12001, 60000)
    client.bucket_select('locked0')
    client.sasl_auth_plain('locked','asdasd')
    #client.bucket_select('locked')
    print('binary on locked')
    print(client.get('aa'))

    client = MemcachedClient('127.0.0.1', 12000, 60000)
    client.sasl_auth_plain('locked','asdasd')
    #client.bucket_select('locked')
    print('binary on locked')
    print(client.get('aa'))

def main():
    client = MemcachedClient('127.0.0.1', 12001, 60000)
    print('binary on default')
    print(client.get('aa'))

    client = MemcachedAsciiClient('127.0.0.1', 12001, 60000)
    print('ascii on default')
    print(client.get('aa'))

def main_b():
    client = MemcachedClient('127.0.0.1', 2222, 60000)
    print('binary on locked client side')
    print(client.get('aa'))

    client = MemcachedAsciiClient('127.0.0.1', 2222, 60000)
    print('ascii on locked client side')
    print(client.get('aa'))


if __name__ == '__main__':
    main()
