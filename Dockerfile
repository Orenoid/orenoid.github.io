FROM mhart/alpine-node:10

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