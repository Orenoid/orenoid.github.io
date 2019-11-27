备忘指南

拉取src分支

```
git clone --single-branch --branch src git@github.com:Orenoid/orenoid.github.io.git
```

考虑到国内网络环境的不稳定性，把整个依赖环境打包到 `orenoid/hexo:latest` 镜像里了

所以直接执行 `run.bat` 即可，跑起来后自动进入docker容器（linux环境下自行调整脚本语法）

生成静态资源

```
hexo g
```

本地预览

```
hexo s
```

其他hexo命令也一样进到容器里执行