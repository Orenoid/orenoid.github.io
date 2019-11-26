---
title: Git与VS Code笔记
date: 2017-2-15 20:39:59
categories: 
- 技术
tags: [Git,VSCode]
---
# 前言

>本文仅作笔记自用，不作参考

　　由于平时没怎么有用Git的习惯，每次用的时候才去现查，结果到头来就记得init/add/commit这几个基础的不能再基础的命令。另一方面虽然用了有一段时间VSCode了，知道它自带Git支持，却因为连Git都不怎么会用，就懒得去了解这个功能了。  
　　这几天又要用到Git，实在觉得有点烦了，决定把Git的基本功能都过一遍，顺带研究下VSCode的Git支持，写个博文记录一下，免得以后又要查老半天。  

<!--more-->

# Git

　　本来是想着系统地学习一下Git的，然后发现这东西远比我想象的要复杂，就怂了，记录一下比较常用的场景和命令就行了。

## 创建修改提交

很基本的命令，没什么好说的
```
git init
git add file
git commit -m "update filename"
git log --pretty=oneline    //参数是为了简化
git status
```
关于工作区/暂存区/版本库的区分，我觉得购物车对暂存区是一个很形象的比喻。  

![](/img/gitvscode/0.jpg)

## 版本跳转

```
git reset --hard HEAD~      // 跳回上一版本
git reset --hard commit_id  // 跳回指定版本号
git log                     // 查看提交历史
git reflog                  // 更全，包括reset的记录
```

## 管理修改

针对修改文件，撤销修改，删除文件等情况
```
git diff HEAD -- file       //查看工作区与版本库区别
git checkout -- file        //撤销工作区的修改
git reset HEAD file         //将暂存区移回工作区

rm file                     //删除文件后
git rm file                 //类似于git add
git commit -m "rm"          //提交

git checkout -- test.txt    //误删后从版本库恢复
```

<!-- git checkout其实是用版本库里的版本替换工作区的版本，无论工作区是修改还是删除，都可以“一键还原”。 git add以后修改呢？？ -->

## 远程仓库

　　通常来讲就是各大代码托管平台了，像国外的Gayhub，国内的Coding等等，我的博客就分别托管在这两个平台上，对国内外IP进行分别解析访问。当然也可以在自己服务器上搭建远程仓库，由于我个人暂时没这个需求，就不研究了。

```
//ssh密钥，部署代码用
ssh-keygen -t rsa -C "youremail@example.com"

git clone gitURL                //将某仓库复制到本地
git remote add origin url       //绑定远程仓库
git push -u origin master       //推送到远程主分支
git remote -v                   //查看远程仓库推送方式
```
>clone下来的仓库会自动绑定远程仓库  
>使用http推送会一直需要口令

## 管理分支

Git的分支系统比较复杂，我仅仅是一知半解，所以只记录一下对我比较常用的场景和命令。

```
git checkout -b branch1             //创建并切换分支
git checkout master                 //切换分支
git merge branch1                   //合并到当前分支

git branch --all                    //查看分支
git branch -d branch1               //删除分支 -D强制删除
```

合并分支有个--no-off参数，我没太搞明白具体意义，回头再看看：[分支管理策略](https://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000/0013758410364457b9e3d821f4244beb0fd69c61a185ae0000)

## 处理冲突

创建分支后，若两边都进行了commit，merge的时候可能会产生冲突，需要手动修改解决。冲突部分会在文件里标出来，像这样：
```
<<<<<<< HEAD
Creating a new branch is quick & simple.
=======
Creating a new branch is quick AND simple.
>>>>>>> branch1
```
把这整一部分改成最终的即可（包括<<<>>>这几行），然后add并commit，就完成merge了。具体参考：[解决冲突](https://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000/001375840202368c74be33fbd884e71b570f2cc3c0d1dcf000)

## 远程分支

如果远程仓库后在clone后新建了分支，需要先用git pull把新分支拉下来。
```
git pull
git branch --all        //查看所有分支，包括远程的
```
不过本地还是需要创建一个新分支，再绑定远程分支。
```
git checkout -b branch1 origin/branch1

...

git push origin branch1
```
另外如果远程仓库有其他人进行了push，那么就需要先pull下来再进行push，并且pull后有可能会与本地产生冲突。  

还有其他很多功能，命令，参数，我暂时就不写了，Git部分到此为止。

# VSCode Git

　　知道Git怎么用之后，VSCode的Git功能就没什么好说的了，一方面VSCode没有Git原生功能多，另一方面VSCode里直接集成了终端，可以在里面直接使用Git。不过借助VSCode在一些交互上还是比在命令行里操作方便不少的。

## 操作命令

在VSCode里按下ctrl+shift+P，输入git，会看到VSCode支持的所有git命令。  
![](/img/gitvscode/1.jpg)

与命令行不同，VSCode里与git add相对应的是git stage，功能比较接近。  
![](/img/gitvscode/2.jpg)

然后就是branch/checkout/commit这些，在ctrl+shift+P输入对应的关键词，就可以看到相关的命令，并且都有具体的解释，没什么好介绍的。

## 冲突合并
VS Code 会检测文件冲突，并以<<<<<,>>>>,====和颜色区分出来。  
![](/img/gitvscode/3.jpg)

## 更改比较
在git文件列表中，单击一个未提交更改的文件，就会打开两个窗口来显示变更的内容。  
![](/img/gitvscode/4.jpg)

总之就写这么多了，上面这些基本足够我日常使用了（大概），后续如果发现了什么更好的功能再做补充，以上。

参考资料：
>[参考资料](https://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000)
>
>[Visual Studio Code 使用Git进行版本控制](http://www.cnblogs.com/xuanhun/p/6019038.html?utm_source=tuicool&utm_medium=referral)