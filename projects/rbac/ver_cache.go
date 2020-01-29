type VersionedLRUCache struct {
	sync.Mutex
	version int
	cache  *LRUCache
}


func NewVersionedLRUCache(size, version int) *VersionedLRUCache {
	return &VersionedLRUCache{
		version: version
		cache: NewLRUCache(size)
	}
}

func (c* VersionedLRUCache) Get(key interface{}) (interface{}, bool) {
	c.cache.Get(key)
}

func (c* VersionedLRUCache) Set(key, value interface{}, version int) {
	c.Lock()
	if c.version == version {
		c.cache.Set(key, value)
	}
	c.Unlock()
}

func (c* VersionedLRUCache) MaybeReset(version int) {
	c.Lock()
	if c.version != version {
		c.cache.Reset()
		c.version = version
	}
	c.Unlock()
}

func (c *LRUCache) Reset() {
	c.Lock()
	defer c.Unlock()

	c.items = make(map[interface{}]*item)
	c.lru = list.New()
}



type userPermissionCache struct {
	sync.Mutex
	version int
	cache  *LRUCache
}

func (c *userPermissionCache) maybeRefreshCache(version int) {
	c.Lock()
	if c.version != version {
		c.cache()
		c.version = version
	}
	c.Unlock()
}

func newPermissionCache(version int) (c *userPermissionCache) {
	c = new(userPermissionCache)
	c.cache = NewLRUCache(1024)
	c.version = version
	return
}

func (c *userPermissionCache) lookup(user, src, permission string) (allowed, found bool) {
	c.RLock()
	allowed, found = c.m[userPermission{user, src, permission}]
	c.RUnlock()
	return
}

func (c *userPermissionCache) set(user, src, permission string, allowed bool, version int) {
	c.Lock()
	if c.version == version {
		c.m[userPermission{user, src, permission}] = allowed
	}
	c.Unlock()
}
