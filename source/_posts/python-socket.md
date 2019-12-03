---
layout: python
title: socket编程指南
s: python-socket
date: 2018-12-02 03:24:14
categories:
- 技术
tags: [Python, 网络, 翻译]
---



> 本文翻译自Python官方文档中的这篇[《Socket Programming HOWTO》](https://docs.python.org/3.8/howto/sockets.html)，作者：Gordon McMillan

#### 摘要

socket几乎到处都有被用到，但却是被误解得最多的技术之一。本文将对对socket进行一个总体的概述，但这并不是真正的教程，要会使用的话还得进一步自己去研究。文章不会对socket相关细节面面俱到（太多了），但是我希望它能提供足够的背景知识，让你像模像样的开始使用套接字。

<!--more-->

#### socket

本文只打算讨论`INET`类型的socket（例如IPv4），事实上至少有99%的场景下用的都是这一类，同时我们也只讨论`STREAM`类型的（例如TCP）。除非你很清楚实际应该怎么选择（那你也没必要阅读这篇指南了），使用 STREAM 类型的套接字将会得到比其它类型更好的表现与性能。 我会尽量帮你弄明白socket是啥以及如何使用阻塞/非阻塞socket，首先会从阻塞式socket开始介绍，先把这个弄明白了才能进一步研究非阻塞式是如何工作的。

理解这些东西的难点之一在于「套接字」可以表示很多微妙差异的东西，这取决于上下文。所以首先，让我们先分清楚「客户端」套接字和「服务端」套接字之间的不同，客户端相当于一个会话终端，而服务端则更像是个接线员。客户端应用（比如浏览器）只会用到客户端socket，而对于服务器来说，这两类socket都要使用到。

#### 历史

进程间通信有各种各样的方法，但目前socket是最受欢迎的一种。如果任意指定一个平台的话，socket可能没某些其他形式的IPC那么快，但如果要做到跨平台通信的话，socket几乎就是唯一选择了。

socket是Berkeley发明的，是Unix的BSD风格的一部分。socket与INET的结合使得与世界各地的计算机进行通信变得异常容易（至少与其他方案相比），因此理所当然地，socket这一通信方案在互联网中得到了迅速扩散。

#### 创建socket

简略地说，当你点击一个链接来到现在这个页面的时候，你的浏览器就已经做了下面这几件事情：

```python
# create an INET, STREAMing socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# now connect to the web server on port 80 - the normal http port
s.connect(("www.python.org", 80))
```

当`connect`成功后，我们就可以通过socket `s`来对页面上的内容进行请求了，然后再通过同一个socket获取响应内容，这些完成之后这个socket就会被销毁（是的，销毁）。客户端套接字通常用来做一次交换（或者说一小组序列的交换）。

上面是客户端的情况，而服务器上的流程稍微复杂一些。首先，服务器会创建一个服务端socket：

```python
# create an INET, STREAMing socket
serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# bind the socket to a public host, and a well-known port
serversocket.bind((socket.gethostname(), 80))
# become a server socket
serversocket.listen(5)
```

这里头有几个需要注意的点：我们用的是`socket.gethostname()`，这样的话这个soccket才是对外部暴露的。如果用的是 `s.bind(('localhost', 80))` 或者 `s.bind(('127.0.0.1', 80))` ，尽管这依旧是个服务端socket，但是它只会对主机内部可见。而`s.bind(('', 80))`指定套接字可以由机器碰巧拥有的任何地址访问。

另一个需要注意的点是：那些数字较小的端口号通常会保留用于一些常见的服务（例如HTTP、SNMP等）。建议自己开发的时候设置一个较大的端口号数字（4位）。

最后，`listen` 方法的参数会告诉socket库，我们希望在队列中累积多达 5 个（通常的最大值）连接请求后再拒绝外部连接。如果你其他带代码写得没问题的话，通常来讲这个数量是足够的了。

现在，我们有了一个监听80端口的服务端socket，可以开始服务端的主循环逻辑了：

```python
while True:
    # accept connections from outside
    (clientsocket, address) = serversocket.accept()
    # now do something with the clientsocket
    # in this case, we'll pretend this is a threaded server
    ct = client_thread(clientsocket)
    ct.run()
```

实际上有三种方式来实现这个循环逻辑：要么分配一个线程来处理客户端线程，要么创建一个新进程来处理，第三种方法则是重构应用逻辑，使用非阻塞式socket，并使用select在我们的服务端socket与任何活动的客户端socket之间进行多路复用，但这个我们之后再介绍。目前最重要的是弄清楚这一点：上面这些全都是服务端socket要干的事情，服务端socket不发送和接收任何数据，它只负责生成客户端socket。每当有某个客户端socket对前面绑定的host和port进行`connect()`操作的时候，服务端socket就会创建一个新的客户端socket来响应对方的请求。而之后，这两个客户端socket之间就可以自由地进行互相通信了，它们所用的端口是由系统动态分配的，当会话结束的时候就会被回收掉。

#### 进程间通信（IPC）

如果你需要在同一台机器上进行两个进程间的快速 IPC 通信，你应该了解管道或者共享内存。如果你决定使用 AF_INET 类型的套接字，绑定「服务端」套接字到 `'localhost'` 。在大多数平台，这将会使用一个许多网络层间的通用快捷方式（本地回环地址）并且速度会快很多

> 参见： [`multiprocessing`](https://docs.python.org/zh-cn/3.7/library/multiprocessing.html#module-multiprocessing) 模块使跨平台 IPC 通信成为一个高层的 API

#### 使用socket

首先要注意的就是，浏览器所用的客户端socket和服务器所用的客户端socket本质上都是相同的，这其实是一个端对端通信。或者换一种说法，就是你作为设计者需要制定一个通信规则。通常来讲，发起连接一方的socket通过发送一个请求或者信号来开始一次会话。但这属于设计决定，并不是socket规则。

我们可以使用`send`和`recv`这两个操作来进行通信，或者也可以把客户端socket转换成file-like对象，然后对其进行读写操作。Java中采用的就是后一种形式，这里不做详谈，不过要提醒一点，采用后一种方案的时候要注意对socket进行`flush`操作。因为它们都是被缓冲了的“文件”，如果不进行`flush`，仅仅是写入数据后等待读取响应数据，那么你有可能永远都收不到响应，因为你写入的请求数据可能还在缓冲里面，压根没有被发送出去。

现在我们来看看socket的主要绊脚石：在网络缓冲区上的`send`和`recv`操作。这两个操作并不一定会完全地处理好你交给他们的数据（或者期望从他们那接收到的数据），因为其主要职责还是处理网络缓冲。通常他们只会在网络缓冲区被存入（send）或取出（recv）的时候才会返回，同时告诉你实际上处理了多少字节，而开发者必须自己多次重复调用这两个方法来确保数据被完全处理好了。

当`recv`操作返回0个字节的时候，这意味着另一侧已经关闭了连接，我们不会从那边收到任何数据了。而你发送的数据可能已经成功送达，这个之后再做讨论。

HTTP协议只会用一个socket来进行一次数据传输，客户端先发送一个请求，随后读取服务端返回的响应，随后这个socket就废弃了。这意味着客户端可以通过检测是否收到0字节响应来判断数据是否已经传输完毕了。（译注：这段应该是指HTTP没有启用Keep-Alive的情况）

但如果你想要复用这个socket，那就意味着你没法在socket上拿到像0字节数据这种传输结束标志的。这里再重复一遍：如果`send`和`recv`处理了0个字节后返回，那么这个连接就已经断开了，反之，如果连接没断开，那么你可能就要一直阻塞在`recv`操作上，socket并不会告诉你接下来已经没有数据了（目前来讲是这样的）。你可已经能想到了：在通信中，一个消息必须要么是固定长度的，要么是有明确边界的，或者是告诉了你这则消息的实际长度，或者就像HTTP协议那样，通过断开连接来告诉你消息已经结束了。这里面任意一个方案都是可行的（但有些方案相对更优一些）。

假如你不想使用断开连接这种方法的话，那么最简单的还是给消息设置一个固定长度。

```python
class MySocket:
    """demonstration class only
      - coded for clarity, not efficiency
    """

    def __init__(self, sock=None):
        if sock is None:
            self.sock = socket.socket(
                            socket.AF_INET, socket.SOCK_STREAM)
        else:
            self.sock = sock

    def connect(self, host, port):
        self.sock.connect((host, port))

    def mysend(self, msg):
        totalsent = 0
        while totalsent < MSGLEN:
            sent = self.sock.send(msg[totalsent:])
            if sent == 0:
                raise RuntimeError("socket connection broken")
            totalsent = totalsent + sent

    def myreceive(self):
        chunks = []
        bytes_recd = 0
        while bytes_recd < MSGLEN:
            chunk = self.sock.recv(min(MSGLEN - bytes_recd, 2048))
            if chunk == b'':
                raise RuntimeError("socket connection broken")
            chunks.append(chunk)
            bytes_recd = bytes_recd + len(chunk)
        return b''.join(chunks)
The sending code here is usable for almost any messagi
```

这里的发送代码几乎适用于任何消息传递方案。在Python里你可以发送字符串并使用`send()`来获取其长度（即使里面包含有`\0`字符也不会有问题）。但很多情况下，负责接收的代码会更复杂一些。（在C语言中可能不会那么麻烦，除非消息已经嵌入`\0`，这种情况下不能使用strlen。)

一个最简单的改进方案是，把消息的第一个字符用来指示消息类型，进而根据类型来确定长度。这时候你需要执行两步`recv`操作，第一次至少获取一个字符，从而得到消息长度，接着循环获取消息剩余的部分。如果你打算采用分隔符的方案，你可以接收任意大小的数据块（对于网络缓冲来说，4096或者8192是一个较为常用以及合适的尺寸），然后在接收到的数据里查找你定好的分隔符。

需要注意的一个复杂情况是:如果您的会话协议允许多个消息被发送到后面(没有某种类型的应答)，并且您向`recv`传递了一个任意的块大小，那么您最终可能会读取下面消息的开头。
你需要把它放在一边，直到需要的时候再拿出来。

在消息头部声明其长度（比如用5位数字字符）这种方法会更复杂，因为你可能没法在一次`recv`中完全接收到这5个字符（信不信由你）。如果只是平时随便写着玩的，你可能不会遇到这种情况，但在高网络负载的情况下，你的代码就会很快出问题，除非你用两个循环来分别获取长度和消息剩余的数据部分。当进行`send`操作时，你会发现也有这种令人讨厌的情况，`send`也并不总是在一次传输中就处理完所有数据。即使读过这篇文章，知道这么一回事了，但你迟早还是会被这个问题坑到的。

#### 二进制数据

通过套接字传送二进制数据是可行的。主要问题在于并非所有机器都用同样的二进制数据格式。比如 Motorola 芯片用两个十六进制字节 00 01 来表示一个 16 位整数值 1。而 Intel 和 DEC 则会做字节反转 —— 即用 01 00 来表示 1。套接字库要求转换 16 位和 32 位整数 —— `ntohl, htonl, ntohs, htons`。 其中的`n`表示 network，`h`表示 host，`s`表示 short，`l`表示 long。在网络序列就是主机序列时它们什么都不做，但是如果机器是字节反转的则会适当地交换字节序。

在现今的 32 位机器中，二进制数据的 ascii 表示往往比二进制表示要小。这是因为在非常多的时候所有 long 的值均为 0 或者 1。字符串形式的 "0" 为两个字节，而二进制形式则为四个。当然这不适用于固定长度的信息。自行决定，请自行决定。

#### 断开连接

严格地说，在断开（`close`）socket之前，需要先对其进行`shutdown`操作。`shutdown`相当于对socket另一侧的一个通知，根据你传递的参数，它可能会传达以下两种不同的信息：“我不会再发送数据了，但还能继续接收”，或者“我不再管你发过来的数据了，谢谢”。但大多数socket库都习惯了开发者会忽略这一规则，索性在`close`的时候，一并执行了真正意义上的`shutdown`和`close`操作。所以大多数情况下，并不需要明确地进行`shutdown`。

#### socket何时销毁

当使用阻塞式socket的时候，可能遇到的最坏的情况是对面还没有执行`close`就突然挂掉了，这种时候你的、socket可能就会一直在那干等着。TCP是一个可靠的协议，这会导致它会等很长很长时间才放弃这个连接。如果你是用线程来处理的，那么这个线程实际上已经跟死掉没什么区别了。对这种情况还真没太多处理办法，但其实这个线程并不会消耗太多的资源，只要你别干什么蠢事，比如进行一个阻塞读取操作的时候又还占有着一个锁之类的。千万不要尝试去杀掉这个线程，线程之所以高效，其中一部分原因就是它们避免了与资源自动回收相关的开销。换句话说，如果你设法把线程给干掉了，那么你可能会把整个程序给搞砸掉。

#### 非阻塞式socket

如果你已经把前面说的这些都弄明白了，那么就已经基本掌握了socket开发的技术要点。接下来你还是会去调用一些相同的接口，但是如果换一个更加正确的方式，你的应用会完全变了个样。

在Python中，可以通过`socket.setblocking(0)`来将一个socket设置为非阻塞的。在C语言里，想这么干会更复杂一些，（一方面，你需要在 BSD 风格的 `O_NONBLOCK` 和几乎无法区分的 Posix 风格的 `O_NDELAY` 之间做出选择，这与 `TCP_NODELAY` 完全不同。）但思路是相同的，先创建socket，然后在使用前变更设置。（如果你疯了的话，你也可以来回切换）

这样做带来的最主要差别就是，`send`、`recv`、`connect`以及`accept`这些操作可以不处理任何东西就进行返回。 你（当然）有很多选择，一种是你自己手动检查返回码和错误码，不过这个大概率会让你疯掉。不信的话，有时候你可以试试看。你的程序将会变得臃肿、易错而且非常废CPU。所以我们还是跳过这个及其费脑的方案，看下一个，一个更正确的方案。

那就是使用`select`。

在C语言中，`select`编程是相当复杂的，而Python中就简单多了，但它与 C 版本也足够接近，如果你在 Python 中理解 `select` ，那么在 C 中你会几乎不会遇到麻烦：

```python
ready_to_read, ready_to_write, in_error = \
               select.select(
                  potential_readers,
                  potential_writers,
                  potential_errs,
                  timeout)
```

`select`一共接收三个列表：第一个包含的是那些你想读取数据的socket，第二个是你想写入数据的，第三个（通常是空的）是出错了的，用于排查。需要注意的一点是，一个socket是可以进入上面多个列表的。`select`操作本身是阻塞的，不过你可以给它设置一个合理的超时期限（比如1分钟），这是个更明智的选择，除非你有充分的理由不这么做。

`select`也会返回给我们三个列表，它们分别包含了可读的、可写的以及报错的socket。对应你上面传入的三个列表，返回的列表都是相应列表的子集（也可能是空的）。

如果一个socket出现在了返回的可读socket列表里，那么你可以认为，对这个socket进行`recv`操作必定能返回些什么。同理，在可写入列表里，你也可以对socket进行发送数据的操作。可能你想要接收/发送的是全部数据，但有总比没有好。（事实上，任何健康的socket都是可写入的，代表的就是网络缓冲区已经可用了而已）

如果你手里有一个服务端socket，可用把它放到上面的`potential_readers`列表里，当它变成可读状态的时候，你就可用对它进行`accept`操作了。而如果你创建了一个新的socket，并尝试与其他人进行`connect`，那么可以把它放进`potential_writers`里面，当这个socket变为可写入状态的时候，就说明已经连接成功了。

实际上，`select`对于阻塞式socket也是很好用的。这是判断是否阻塞的一种方法——当缓冲区中有内容时，socket作为可读状态返回。然而，这仍然无法帮助确定另一端是否已经完成，或者只是忙于其他事情。

**可移植性警告：**在Unix平台，`select`对socket和文件都有用，但在Windows平台不要尝试这么做。Windows下，`select`仅对socket起作用。在C语言中也同样要注意，很多socket的高级功能在Windows上是以不同方式去实现的。事实上，在Windows平台我通常是用线程来处理socket的（效果非常，非常的好）。

