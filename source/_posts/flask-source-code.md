---
title: Flask源码阅读笔记
s: flask_source_code
date: 2019-11-23 03:07:05
categories:
- 技术
tags: [Python,Flask]
---



Flask和Django都是基于wsgi协议去实现的Python Web框架。本文将从与开发者相关度最高的地方入手：请求处理。

根据wsgi协议的规定，application需要提供一个callable对象给服务器（或中间件，后略），分别接收两个参数：environ字典与start_resposne函数（当然也可以是其他callable对象），这两个参数通常由服务器传入。Python官方提供了一个简单的例子：

```python
def demo_app(environ,start_response):
    from io import StringIO
    stdout = StringIO()
    print("Hello world!", file=stdout)
    print(file=stdout)
    h = sorted(environ.items())
    for k,v in h:
        print(k,'=',repr(v), file=stdout)
    start_response("200 OK", [('Content-Type','text/plain; charset=utf-8')])
    return [stdout.getvalue().encode("utf-8")]
```
<!--more-->
当服务器收到请求时，就会去调用框架提供的callable对象，解析HTTP请求，构造environ字典，和start_response函数一并传入。而在flask中，这个callable对象就是由Flask类构造而来的，它的`__call__`方法是这样的：

```python
    def __call__(self, environ, start_response):
        return self.wsgi_app(environ, start_response)
```

可以看到只是单纯的转交给了`wsgi_app`方法，根据源码文档里的解释，这么设计的目的是为了在我们需要使用wsgi中间件的时候，可以这样：

```python
# 通常做法
app = MyMiddleware(app)
# 第二种
app.wsgi_app = MyMiddleware(app.wsgi_app)
```

使用第二种方式添加中间件的话，可以保留对app对象的引用，避免被中间件包裹后失去对app原有API的使用权。

接着是`wsgi_app`方法的代码：

```python
    def wsgi_app(self, environ, start_response):
        # 构造上下文
        ctx = self.request_context(environ)
        error = None
        try:
            try:
                # 将上下文推入栈中
                ctx.push()
                # 处理请求
                response = self.full_dispatch_request()
            except Exception as e:
                error = e
                response = self.handle_exception(e)
            except:  # noqa: B001
                error = sys.exc_info()[1]
                raise
            return response(environ, start_response)
        finally:
            if self.should_ignore_error(error):
                error = None
            # 最后必须确保将上下文弹出，避免干扰其他请求
            ctx.auto_pop(error)
```

整体逻辑相当简洁，基本都是高层级的抽象，先处理上下文，然后处理请求和捕获错误，最后确保上下文被弹出。

我们先展开讲一下flask的上下文机制。Flask提供了两种上下文，分别是请求上下文和应用上下文。这两类上下文的生命周期基本上相等的，每处理一个请求，就会相应地创建一个请求上下文和应用上下文。

实际上Flask在早期版本中，只有请求上下文的概念。但后来开发者发现，在有些场景下我们并没有构造请求的必要性，但是需要用到应用的一些内部资源或配置、参数（例如数据库连接），如果仅仅是为了获取应用上下文而强行构建一个请求上下文的话，这种方案又过于不合理，于是flask后来将这两类上下文区分开来了。

说完上下文机制，我们继续回来看上面的`wsgi_app`方法，上下文入栈之后，flask会调用`full_dispatch_request`方法来生成响应数据：

```python
    def full_dispatch_request(self):
        """Dispatches the request and on top of that performs request
        pre and postprocessing as well as HTTP exception catching and
        error handling.

        .. versionadded:: 0.7
        """
        # 先执行before_first_request注册的中间件函数列表
        self.try_trigger_before_first_request_functions()
        try:
            # 触发request_started信号
            request_started.send(self)
            # 调用开发者注册的before_request中间件
            rv = self.preprocess_request()
            if rv is None:
                # 若返回None，说明中间件没有拦截请求，继续处理
                rv = self.dispatch_request()
        except Exception as e:
            # 若执行过程出错，尝试使用开发者注册的错误处理器进行错误处理
            rv = self.handle_user_exception(e)
        # 此处的rv实际上就是视图函数返回的响应数据实体，把它再包装成一个callable对象
        return self.finalize_request(rv)
```

