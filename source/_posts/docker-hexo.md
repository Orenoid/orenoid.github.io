---
title: 博客Docker化实践
s: docker-hexo
date: 2019-10-15 02:08:57
categories:
- 技术
tags: [hexo,Docker]
---

前段时间学习了Docker的基本使用之后，决定借助Docker来解决麻烦的博客迁移问题。

我的博客是基于Hexo与Github Pages来实现的，属于静态博客。实际上从17年就开始折腾了，然后中途换了两次电脑，每次把npm依赖环境以及博客文件迁移到新电脑上都很麻烦。比如安装新环境，因为我不是前端，对工具不熟悉，每次都得边操作边查。装完后还得研究Hexo的配置，如果版本跟以前的不兼容的话，旧的配置文件基本就作废了，又得从头看文档。同理还得安装主题，又得把上面的问题过一遍，而且中途还会因为国内糟糕的网络环境衍生出更多烦人的问题。

所以这次决定借助docker来简化迁移流程，让自己少掉点头发。
<!--more-->
首先简单构思了下整个流程应该怎么走，理想的情况应该是，当我换新电脑后，不进行任何物理拷贝，只需要从Github拿到博客的源文件（文章，图片，配置文件等等），然后借助Docker快速把环境搭建起来，就可以开始写新文章了。

OK，需求有了，接下来就要看怎么设计了。

第一步，要把源文件放到Github上，最简单的方法就是在博客对应的Repo下开一个新分支，专门用来放源文件，master分支依旧用于部署博客的静态文件，很简单。

接着是Docker环境，在网上查了下，看到有人采用的方案是，构建一个镜像，然后每次运行hexo命令都要跑一个容器，这显然太过于笨重了。我的思路是构建好镜像后，只开一个容器，往后需要在npm环境下进行的操作都进到容器终端里运行，这个容器就一直用下去了，平时也没必要运行，毕竟我们这是静态博客，容器提供的是操作环境，而非服务，需要的时候再把容器跑起来就好了。

以下是我的Dockerfile：

```dockerfile
FROM mhart/alpine-node:10

# 给apk换源
RUN echo https://mirrors.aliyun.com/alpine/v3.8/main > /etc/apk/repositories; \
    echo https://mirrors.aliyun.com/alpine/v3.8/community >> /etc/apk/repositories

RUN \
    apk --update --no-progress --no-cache add git openssh

WORKDIR /hexo

RUN \
    npm --registry https://registry.npm.taobao.org install hexo-cli@3.1.0 -g \
    && hexo init . \
    && npm --registry https://registry.npm.taobao.org install hexo-generator-feed@2.1.1 hexo-generator-searchdb@1.2.0 hexo-deployer-git@2.1.0 \
    && git clone --branch v7.5.0 --depth 1 https://github.com/theme-next/hexo-theme-next themes/next \
    && rm -rf /hexo/_config.yml /hexo/themes/next/_config.yml /hexo/source \
    && yarn cache clean \
    && npm cache clean --force

EXPOSE 4000

VOLUME ["/hexo/_config.yml", "/hexo/themes/next/_config.yml", "/hexo/source", \
    "/hexo/themes/next/source/images/avatar.png", "/hexo/themes/next/source/images/favicon.ico", "/tmp/.ssh"]

COPY docker-entrypoint.sh docker-entrypoint.sh

CMD ["sh", "docker-entrypoint.sh"]
```

前面就是依赖安装，主要是git和hexo要用到的npm包，为了防止以后出现版本不兼容问题，给每个依赖都指定了具体版本，包括next主题，通过git clone的时候指定tag来选择版本。这样一来，不管官方怎么更新，至少能确保我的博客保持一个稳定可用的状态。之后如果有什么好用新特性，再考虑迁移也不迟。

另一个重要部分就是文件挂载，得把从Github拿到的源文件挂载进容器里，主要就是那些需要我们自定义的东西，比如文章、配置、媒体资源等等，剩下的都由框架自动生成，打包在镜像里即可。

挂载的时候不允许对已存在文件进行挂载，而里头有几个文件，在框架初始化的时候会自动生成，所以要先手动删除掉。

```shell
rm -rf /hexo/_config.yml /hexo/themes/next/_config.yml /hexo/source
```

部署的时候，需要用到ssh密钥，所以还需要把密钥也挂载进容器里，这里遇到个坑，因为我平时的个人主力电脑是Windows系统，密钥直接挂载进去的话，Windows与Linux的权限模型并不一致，部署的时候会遇到权限问题。这里采用的方案是先把密钥文件挂载到一个临时目录，然后在容器内部复制到`/root/.ssh`目录下，再对拷贝的副本进行权限修改。

这样流程基本上就可以走通了，把镜像构建起来后直接推送到Docker Hub上面，以后直接拉取即可，免去漫长而痛苦的构建过程。由于运行容器时要设置的参数还挺多的，写了个bat脚本，因为暂时没有在Linux下搭建环境的需求，就没写shell脚本。顺便写了个Readme文件，作为备忘指南。

这样一来，以后换新电脑，就只需要两步操作了：

1. git clone获取源文件
2. 拉取现成docker镜像，运行容器

然后进容器就可以进行各种常规操作了，比如我这篇博客就是在新环境和新流程下写出来的。