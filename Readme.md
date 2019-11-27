## 备忘指南

> 流程以及相关文件都是针对我个人博客定制的，不具有普适性

拉取src分支

```
git clone --single-branch --branch src git@github.com:Orenoid/orenoid.github.io.git
```

考虑到国内网络环境的不稳定性，把整个依赖环境打包到 `orenoid/hexo:latest` 镜像里了

可选择直接使用docker hub现成镜像，Windows环境下直接执行 `run.bat`（**记得修改ssh挂载路径**）

或重新构建：

```shell
docker build -t orenoid/hexo:latest
```

跑起来后进docker容器执行hexo相关命令

生成静态资源：`hexo g`

本地预览：`hexo s`

部署：`hexo clean && hexo d`