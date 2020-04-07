---
title: Docker build优化小技巧
s: docker-build-optimize
date: 2020-03-13 20:57:10
categories:
- 技术
tags: [Docker]
---

最近开发项目调试的时候改用Docker来运行，主要是为了让开发环境和生产环境尽可能一致。但开发过程中很快发现一个问题，Docker构建镜像太慢了，每次改了一点代码，想要debug就得重新构建，然后要等它下载一堆依赖。开发了一天后，忍不了了，抽空查了下Docker build缓存的相关资料。

<!--more-->

虽然一直知道Docker有分层文件系统这回事，也知道文件层可以在构建过程中重复使用，但没弄清楚到底什么情况才能触发缓存功能。按照网上查到的说明，只要Dockerfile和相关文件没有改动，那么在重新构建的时候就可以利用在本地中缓存的一些镜像层。

如果我们只是改动了一些代码，而项目的依赖清单没有变化，那么显然是没有理由每次都要下载一遍的。那么为什么我之前老是要重新下载呢？先看一个Dockerfile。

```dockerfile
FROM python:3.8.2-alpine3.10

WORKDIR /data/code/project

COPY app app
COPY config.py manage.py ./
COPY requirements requirements

RUN echo https://mirrors.aliyun.com/alpine/v3.10/main > /etc/apk/repositories; \
    echo https://mirrors.aliyun.com/alpine/v3.10/community >> /etc/apk/repositories

RUN apk add --no-cache --virtual .build-deps gcc libc-dev linux-headers tzdata;\
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    pip install --no-cache-dir -r requirements/dev.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/; \
    apk del .build-deps;

# 剩余其他命令……
```

这是我项目中使用的Dockerfile前半部分。根据搜索引擎提供的资料，Docker在根据Dockerfile构建镜像的时候，它会判断是否可以重复利用以前构建生产的镜像。对大多数命令来说，只要命令的文本没变化，那么就可以利用缓存。而对于COPY命令，还会额外判断复制的文件内容是不是变化了。

如果是这样，我只是改了一点代码，requirements文件夹和pip install命令都没有任何变化，为何还会重新下载？

我看了下构建时的日志，发现到WORKRDIR这一层还有Using Cache的标记，而到COPY app app的时候就没了。巧了，我改的代码就是在app目录里头的。于是我接着看网上的文章，发现里面还提到了一条缓存规则：

> 如果某一层利用不了缓存，那么后续的层都将不会从缓存中加载

![](/img/docker_build_opt/cache-algorithm.png)

根据这条规则，再看回前面的Dockerfile，就找到问题所在了。由于我在安装依赖之前就先把所有代码先复制到镜像里，导致只要有任何代码改动就会导致后面所有层的缓存连带着失效。而实际上如果只是改了代码，而依赖没有变化，那么完全是没有必要重新下载的。所以我们对Dockerfile做一点调整：

```dockerfile
FROM python:3.8.2-alpine3.10

WORKDIR /data/code/project

COPY requirements requirements

RUN echo https://mirrors.aliyun.com/alpine/v3.10/main > /etc/apk/repositories; \
    echo https://mirrors.aliyun.com/alpine/v3.10/community >> /etc/apk/repositories

RUN apk add --no-cache --virtual .build-deps gcc libc-dev linux-headers tzdata;\
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    pip install --no-cache-dir -r requirements/dev.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/; \
    apk del .build-deps;

COPY app app
COPY config.py manage.py ./
# 剩余其他命令……
```

这样一来，当初次构建完镜像之后，只要依赖没有变动，再次构建的时候都可以有效利用缓存，无需重新下载了。通过这个技巧，可以大幅提升构建速度，同时提高开发调试的效率。

参考链接：[Faster or slower: the basics of Docker build caching](https://pythonspeed.com/articles/docker-caching-model/)

