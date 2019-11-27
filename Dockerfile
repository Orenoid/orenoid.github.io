from orenoid/hexo:base

RUN rm -rf /hexo/_config.yml /hexo/themes/next/_config.yml /hexo/source

VOLUME ["/hexo/_config.yml", "/hexo/themes/next/_config.yml", "/hexo/source", \
    "/hexo/themes/next/source/images/avatar.png", "/hexo/themes/next/source/images/favicon.ico", "/root/.ssh"]

CMD ["sh"]