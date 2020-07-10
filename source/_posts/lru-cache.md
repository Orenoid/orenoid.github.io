---
title: Python标准库lru_cache源码解读与改造
s: lru_cache
date: 2020-03-13 07:41:42
tags: [Python]
categories:
- 技术
---

之前写一个小项目需要用到过期缓存功能，因为想尽量轻量一些，只在内存中进行缓存，不打算走IO。虽说Python官方的lru_cache很好用，但是偏偏又不提供过期功能。简单搜了下，发现有人提供了[一个附带过期功能的版本](https://gist.github.com/Morreski/c1d08a3afa4040815eafd3891e16b945)。<!--more-->代码如下所示：

```python
from datetime import datetime, timedelta
import functools


def timed_cache(**timedelta_kwargs):                                              
                                                                                  
    def _wrapper(f):                                                              
        update_delta = timedelta(**timedelta_kwargs)                              
        next_update = datetime.utcnow() + update_delta                            
        # Apply @lru_cache to f with no cache size limit                          
        f = functools.lru_cache(None)(f)                                          
                                                                                                                      
        @functools.wraps(f)                                                       
        def _wrapped(*args, **kwargs):                                            
            nonlocal next_update                                                  
            now = datetime.utcnow()                                               
            if now >= next_update:                                                
                f.cache_clear()                                                   
                next_update = now + update_delta                                
            return f(*args, **kwargs)                                             
        return _wrapped                                                           
    return _wrapper
```



看了下他的代码，实现方式很简单，就是在官方的lru_cache外面又包了一层，然后自己管理缓存的过期期限。但细看之后发现这个装饰器有个很大的问题，它会在过期的时候把所有缓存的函数返回结果清空掉，哪怕B比A要晚缓存了一个小时，只要A一过期，就会把其他的缓存一并清空掉。这显然不合理也不好用，理想情况应该是每个参数组合都有自己的过期期限，互相独立，互不干扰。

按理说这个逻辑并不复杂，只要在增加/获取缓存的同时，加上过期时间的存储和判断即可，原本我准备上面的样例那样给官方的装饰器再包装一层，但很快发现做不到这一点，因为官方的`lru_cache`只对外暴露了两个操作缓存的接口，分别是`func.cache_info()`和`func.cache_clear()`，查看缓存命中统计和清空缓存，没办法对cache字典的单个key进行操作（缓存其实就是存在了一个叫cache的字典里，后面看源码就知道了）。所以如果要对每个key做独立的过期，就必须改动内部逻辑了。其实到这里，从实用的角度出发，直接找第三方库是比较合理的。不过我出于兴趣，决定自己来实现一下。

要改，那么自然要先读。这里简单过一下Python3.6的`lru_cache`实现。

```python
def lru_cache(maxsize=128, typed=False):
    if maxsize is not None and not isinstance(maxsize, int):
        raise TypeError('Expected maxsize to be an integer or None')

    def decorating_function(user_function):
        wrapper = _lru_cache_wrapper(user_function, maxsize, typed, _CacheInfo)
        return update_wrapper(wrapper, user_function) # 返回的是函数，不是函数结果
    return decorating_function
```

要读懂这段代码需要对Python的装饰器工作原理有一定了解，本文不做赘述。这段代码显然没涉及太多逻辑，开头校验下参数，把函数和装饰器参数传进了`_lru_cache_wrapper`函数，后面的update_wrapper只是做了些属性转移的工作，跟缓存功能没太大关系。我们再进到`_lru_cache_wrapper`函数看看，实际上主要的缓存逻辑实现都在这里头了。接下来分段来做解读。

```Python
def _lru_cache_wrapper(user_function, maxsize, typed, _CacheInfo):
    sentinel = object()          # 用来判断缓存是否命中的唯一标识
    make_key = _make_key         # 根据参数生成缓存key的函数
    PREV, NEXT, KEY, RESULT = 0, 1, 2, 3   # 给下面链表的节点对应位置命名，提升可读性

    cache = {}				 # 用来缓存的字典
    hits = misses = 0		 # 缓存命中统计
    full = False			 # 缓存是不是满了
    cache_get = cache.get
    cache_len = cache.__len__
    lock = RLock()           # 链表操作是非线程安全的，需要加锁
    root = []                # 环形双向链表的根节点
    root[:] = [root, root, None, None]     # 链表初始化
```

这里基本都是些初始化，光看这部分可能会有点云里雾水的，主要还得看后面都对这些常量、变量做了些什么事情。先简单说下`lru_cache`的实现原理，它是借助Python字典和双向环形链表来实现的。

`root`就是这个链表的根节点，`root`是个数组，链表里的其他节点也是这个结构，分别包含四个部分：前节点（PREV），后节点（NEXT），字典键（KEY）和函数结果（RESULT）。在通常情况下，根节点的左侧（PREV）是最后被访问的数据，而右侧（NEXT）则是最旧的缓存。这个链表的作用是维护缓存的访问顺序，确保在缓存满了的情况下能够进行时间复杂度为O(1)的缓存增加与删除操作。

而`cache`是个字典，它的键是由函数参数生成的哈希对象，和链表结点里的KEY是同一种东西。而字典的value则是不一定的，在不同情况下存的东西并不一样，但抽象意义上来讲都可以理解为函数返回结果，它的作用就是用来快速获取缓存中的函数返回结果，时间复杂度为O(1)。

这么说还是有点抽象了，先看代码，官方的实现里对`maxsize`的两种特殊情况做了单独实现，一种是不需要缓存的情况，一种是缓存没有上限的情况。

```python
    if maxsize == 0:
        def wrapper(*args, **kwds):
            nonlocal misses
            result = user_function(*args, **kwds)
            misses += 1
            return result
    elif maxsize is None:
        def wrapper(*args, **kwds):
            # Simple caching without ordering or size limit
            nonlocal hits, misses
            key = make_key(args, kwds, typed)
            result = cache_get(key, sentinel)
            if result is not sentinel:
                hits += 1
                return result
            result = user_function(*args, **kwds)
            cache[key] = result
            misses += 1
            return result
```

第一种没啥说的，简单提下第二种，这里cache的value直接存的是函数的返回结果，逻辑很好读懂，如果有缓存则返回缓存，没有则调用`user_function`，并将函数结果缓存起来。`setinal`的作用就是作为唯一标识，判断函数结果是否已经缓存了，不用None是为了防止有些函数返回的可能就是None。并且由于上面对字典的操作都是线程安全的，所以也用不到锁。而且我们发现这里也压根没用到链表。

接下来就是第三种，设置了`maxsize`的情况。

```python
    # ...
    else:

        def wrapper(*args, **kwds):
            nonlocal root, hits, misses, full
            key = make_key(args, kwds, typed)
            with lock:
                link = cache_get(key)
                if link is not None:
                    link_prev, link_next, _key, result = link
                    link_prev[NEXT] = link_next
                    link_next[PREV] = link_prev
                    last = root[PREV]
                    last[NEXT] = root[PREV] = link
                    link[PREV] = last
                    link[NEXT] = root
                    hits += 1
                    return result
            result = user_function(*args, **kwds)
            with lock:
                if key in cache:
                    pass
                elif full:
                    oldroot = root
                    oldroot[KEY] = key
                    oldroot[RESULT] = result
                    root = oldroot[NEXT]
                    oldkey = root[KEY]
                    oldresult = root[RESULT]
                    root[KEY] = root[RESULT] = None
                    del cache[oldkey]
                    cache[key] = oldroot
                else:
                    last = root[PREV]
                    link = [last, root, key, result]
                    last[NEXT] = root[PREV] = cache[key] = link
                    full = (cache_len() >= maxsize)
                misses += 1
            return result
```

这部分主要分为两部分逻辑，缓存命中和未命中。前面初始化的链表和锁到这里才派上了用场。

缓存命中时，需要把原先的缓存节点移动到`root`节点的左侧，作为最近访问节点。

而未命中时，需要先调用`user_function`获取结果，然后又出现了两种分支逻辑：缓存满了和没满。

如果没满，就只需要简单地把新节点插入到`root`前面即可，记得更新下`full`变量。

如果缓存满了，就把新结果放进当前root节点，最旧的缓存节点设置为新的root，并清除数据，更新cache。

这里配合下面的数据结构图可能会好理解一点。

![](/img/lru_cache/01.webp)

剩下的其实是些相对不太重要的代码了，就是对外暴露一些操作接口，这里不贴上来了。

看完源码后，现在知道工作原理了，其实要实现过期功能，就只需要在旧的逻辑里，插入处理过期逻辑的代码即可。这里就说下大致思路，不贴代码了。完整代码可以点[这里](https://gist.github.com/Orenoid/bc011c7bb60c128d2767739fead29cc1)查看。

1. 当`maxsize`为0的时候，没有缓存，所以不变。
2. 当`maxsize`为`None`的时候，即缓存没有上限，我们对字典的`value`稍作调整，把函数结果和缓存时间一起存进去，然后在取值的时候，判断是否已经过期，过期的话就按照缓存未命中处理，重新调用`user_function`并缓存结果即可。
3. 当`maxsize`为大于0的时候，我们把缓存的时间一并存入到链表的节点里，只被动过期，在命中缓存的时候，判断是否已经过期了，是的话，就把节点移除掉，当然也要记得更新`cache`，然后按照缓存未命中的逻辑继续往下走就行了。

大致逻辑是这样，剩下的都是一些细节上的处理。另外我在重新实现的时候，重新封装了一个类来作为链表的节点，而不是像官方那样用的数组，差不多就这些了。