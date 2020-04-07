## 备忘指南

> 本流程以及相关文件都是针对我个人博客定制的，不具有普适性

拉取src分支，进入Repo目录

```
git clone --single-branch --branch src git@github.com:Orenoid/orenoid.github.io.git
```

执行 `run.bat`（**记得先修改ssh挂载路径**），会拉取并运行Docker Hub上的现有镜像

随后在Docker容器内执行hexo相关命令即可

---------------------------------------
常用命令：

生成静态资源：`hexo g`

本地预览：`hexo s`

新建文章：`hexo new -s 文件名 文章标题`

将草稿发布为文章：`hexo publish post <file_name>`

部署：`hexo clean && hexo d`

---------------------------------------
__P.S.__ 若Docker Hub不可用，可于本地构建镜像，然后跟前面一样，执行`run.bat`即可
```shell
docker build -t orenoid/hexo:latest .
```