FROM mhart/alpine-node:10

RUN echo https://mirrors.aliyun.com/alpine/v3.8/main > /etc/apk/repositories; \
    echo https://mirrors.aliyun.com/alpine/v3.8/community >> /etc/apk/repositories

RUN \
    apk --update --no-progress add git openssh

WORKDIR /hexo

VOLUME ["/hexo"]

EXPOSE 4000

RUN \
    npm --registry https://registry.npm.taobao.org install hexo-cli@3.1.0 hexo-generator-feed@2.1.1 hexo-generator-searchdb@1.2.0 -g --save

CMD ["sh"]
