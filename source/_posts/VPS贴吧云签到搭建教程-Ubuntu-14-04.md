---
title: VPS贴吧云签到搭建教程 基于Ubuntu 14.04
date: 2017-01-19 09:24:38
categories: 技术
tags: [Ubuntu,云签到]
---

![](/img/15.png)
　　之前在新浪云上也搭过一个云签到，因为懒的原因一直没想把它迁移到自己的服务器上，奈何新浪后来改了扣费标准，云豆的消耗翻了一番，所以这几天抽空在服务器上搭了一个，顺便升到了最新版。  
　　安装之前在网上搜了一下，发现云签到的相关教程基本上都是基于各种PaaS平台,基于VPS搭建的屈指可数，找到的也不够详细。所以搭建完成以后决定写下整个流程，一方面是供别人参考，一方面是做个记录，以及给自己博客填充点东西。。  
　　开始之前先强调一下，本流程并不保证能完全正确，跟你的实际环境很可能会有出入，所以遇到问题请善用搜索。

<!--more-->
# 准备工作

整个搭建流程需要具备以下这些东西：  
1. VPS , Ubuntu系统  
2. apache2 , php , mysql , phpmyadmin  
3. [Git 工具](http://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000)  
4. [云签到源码](https://github.com/MoeNetwork/Tieba-Cloud-Sign)  
5. 基本的linux命令行操作知识

附：这一部分是我在比较早之前就配置过的了，所以是直接参照当初用的教程写的。

## 安装apache2
在命令行输入：  
```bash
$sudo apt-get install apache2
```
安装完成后运行如下命令重启一下：  
```bash
$sudo service apache2 restart
```
在本地浏览器输入服务器IP（如果有域名就输入域名，下面同理），如果打开的是这样一个页面，显示"It works!",那么就说明安装成功了。  
![](/img/1.png)  
Apache2的默认文件目录是/var/www/html，浏览器所访问的初始文件index.html就在这里面。  
附：Apache2本身的配置文件目录是 /etc/apache2  

## 安装php
命令行输入：
```bash
$sudo apt-get install libapache2-mod-php5 php5
```
此外建议安装扩展 php5-gd php5-mysql 安装方式同上（这里出自原参考文档，我也不确定自己当时装了没）  
安装完成后再重启下apache2:
```bash
$sudo service apache2 restart
```
接下来我们在html目录下新建一个test.php文件来测试是否能正常运行：
```bash
$sudo vi /var/www/html/test.php
```
然后输入：
```bash
<?php echo "hello,world!"?>
```
保存退出后，在本地浏览器输入：服务器IP/test.php,若能显示hello,world字样，则证明安装成功了。  

## 安装MySQL数据库
```bash
$sudo apt-get install mysql-server mysql-client
```
apt-get程序会自动下载安装最新的mysql版本。在安装的最后，它会要求里输入root的密码，注意，这里的root密码指的不是Ubuntu的root密码，是你要给MySQL设定的root密码。  

## 安装phpmyadmin-Mysql数据库管理
```bash
$sudo apt-get install phpmyadmin
```
phpmyadmin设置：  
在安装过程中会要求选择Web server：apache2或lighttpd，使用空格键选定apache2，按tab键然后确定。然后会要求输入设置的Mysql数据库密码连接密码Password of the database’s administrative user。  
然后将phpmyadmin与apache2建立连接，以我的为例：www目录在/var/www/html，phpmyadmin在/usr/share/phpmyadmin目录，所以就用命令：
```bash
$sudo ln -s /usr/share/phpmyadmin /var/www/html
```
phpmyadmin测试：在浏览器地址栏中打开:服务器IP/phpmyadmin，这里后面搭建的时候还要用到。

## 设置Ubuntu文件执行读写权限
　　组建安装好之后，PHP网络服务器根目录默认设置是在：/var/www。由于Linux系统的安全性原则，改目录下的文件读写权限是只允许root用户操作的，所以我们不能在www文件夹中新建php文件，也不能修改和删除，必须要先修改/var/www目录的读写权限。在界面管理器中通过右键属性不能修改文件权限，得执行root终端命令：
```bash
$sudo chmod 777 /var/www
```
然后就可以写入html或php文件了。777是linux中的最高权限，表示可读，可写，可执行。  

## Git 安装
这个主要是为了能从GitHub上方便快捷的获取各种源码用的，如果你非要不装也不是不可以，能把源码下下来就行。  
具体流程恕我不再详细说明了，内容较多，请自行查阅，[廖老师的教程](http://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000)已经足够详细了。

至此，准备工作就算基本完成了。

# 云签到安装

接下来可以开始搭建工作了，首先我们要到GitHub上面获取站点源码。
## 下载源码
通过Git命令可以很快速地下载到本地：
```bash
$git clone https://github.com/MoeNetwork/Tieba-Cloud-Sign.git
```
将代码放到 /var/www/html 目录下，记得将里面原来的index.html改名或删除。  
注意：是将Tieba-Cloud-Sign里的文件放到该目录下，而不是Tieba-Cloud-Sign整个文件夹。

## 修改config.php
找到根目录下的config.php文件，修改相关数据。不建议修改其它的，数据库名称默认就可，只设置好你的数据库的密码即可，最后一行填写乱码就可。  
![](https://dn-chinmax.qbox.me/wp-content/uploads/2015/10/tiebayunqiandaoconf.png)
（这里借下[原博](https://okwoo.com/build-baidu-cloud-vps-registration-tutorial)的图，懒得截自己的图打码了）

## 安装数据库
为了安装过程顺利，我们最好手动安装数据库。首先在浏览器输入：服务器IP/phpmyadmin  
成功进入后台之后，新建一个名字叫tiebacloud的数据库（与你在上一步中设定的数据库名称相同）。<br>
![](/img/9.png)
## 开始安装
在本地浏览器输入服务器IP，根据一系列提示开始安装。  

### 点击“前往安装”
![](/img/10.png)

### 阅读协议
（反正你也不会读）选择“我接受”。在弹出的对话框内，点击“确定”。
![](/img/11.png)

### 功能检查界面  
在这里我遇到了一个问题，印象中是不支持Curl导致无法签到之类的：[解决方案](http://jingyan.baidu.com/article/a681b0de39c47d3b1943467a.html)  
没什么问题的话就直接下一步<br>
![](/img/12.png)
附：虽然我上面说有问题，但我还是直接下一步了，后面搭建好运行时才又出了问题，用的是上面提供的解决方案。

### 设置运行环境界面
由于我们的VPS是Linux系统，选择“不，我不是”。
![](/img/13.png)

### 设置所需信息界面
在自动获得数据库配置信息里，选择“是”。这里填的就是你之后登录用的管理员账号，填写相关信息后“下一步”。
![](/img/14.png)
### 安装完成
![](https://dn-chinmax.qbox.me/wp-content/uploads/2015/10/tiebayunqiandaoguide6.png)
然后如果又跳回一开始的界面，就按照它说的在setup目录下创建一个install.lock空文件即可。
### crontab定时设置
接着在服务器计划任务里添加do.php，命令行输入：
```bash
crontab -e
```
然后在文件里添加这一行代码：
```bash
* * * * * /usr/bin/php -f /var/www/html/do.php
```
保存退出，然后重启服务：
```bash
$sudo service cron restart
```
改一下do.php的执行权限：
```bash
$sudo chmod +x /var/www/html/do.php
```
# 后续配置
到这里就算是搭建完成了，剩下的就是对网站做一些设置，以及装一些插件（可选）。
## 网站设置
用管理员账号登录后，按照网站提示绑定百度账号，推荐用手动绑定。<br>
![](/img/2.png)
绑定账号之后，进入云签到设置，刷新自己的贴吧列表。<br>
![](/img/3.png)
在设置中心-签到设置里，保持默认即可。签到时间设置“0”，即从凌晨1点开始签到。<br>
![](/img/4.png)
如果要手动测试能否执行签到，在浏览器输入：服务器IP/do.php，会即刻执行。
![](/img/5.png)

## 安装插件和样式

接下来讲一下怎么给网站安装一些作者提供的插件：[插件库](http://git.oschina.net/kenvix/Tieba-Cloud-Sign/wikis/%E8%B4%B4%E5%90%A7%E4%BA%91%E7%AD%BE%E5%88%B0%E6%8F%92%E4%BB%B6%E5%BA%93)<br>
![](/img/6.png)
这里我们以更换背景插件为例：<br>
![](/img/7.png)
获取插件git链接后，进入plugins目录：
```bash
$cd /var/www/html/plugins
$sudo git clone https://github.com/chajianku/mok_bgimg.git
```
如果你没有安装Git的话，就直接下下来放到plugins文件夹里。  
安装完成后进入插件管理页面就可以看到新装的插件了：
![](/img/8.png)
然后安装并激活插件就可以了，样式的安装方法同理。

# 结尾

至此，整个流程就算是结束了，如果有什么不对的地方欢迎指正。  

转载请标明出处，谢谢。  

参考资料：
>[VPS搭建百度贴吧云签到详细教程](https://okwoo.com/build-baidu-cloud-vps-registration-tutorial)
>
>[ubuntu下安装Apache+PHP+Mysql](http://www.cnblogs.com/lynch_world/archive/2012/01/06/2314717.html)
>
>[linux使用crontab实现PHP执行计划定时任务](http://www.jb51.net/article/49983.htm)