---
title: Python装饰器与单元测试
s: decorator-unittest
date: 2019-08-07 06:27:56
categories:
- 技术
tags: [Python]
---
最近在给一个项目写单元测试的时候遇到一个问题，如何对带装饰器的函数进行测试。

先说说问题是怎么来的。在我看来，单元测试，顾名思义应该以最小单元作为测试对象，而装饰器与原函数明显是两个不同的功能单元，所以我觉得两者应该分开进行测试。
尽管我们可以图省事直接对新函数直接进行测试，但是会对导致测试结果不够直观，比如说我改动装饰器的时候写了个BUG，但是从单元测试体现出来的是，原函数出问题了，尽管我压根没动过它的代码。所以就诞生了这么一个需求，如何获取被装饰过的原函数。
<!--more-->
在群里跟别人讨论这个问题的时候，有人反驳我说你可以给装饰器和新函数各写一个测试，装饰器的测试用例没出问题，新函数出问题了，那么不就是原函数出问题了吗？
从结果上来说，确实可以判断BUG来源，但是这样真的太丑了，得靠多个测试用例才能联合判断出BUG出在谁身上了，这样毫无“单元”性可言了。
并且装饰器大概率是要复用在不同函数上的，这就意味着你需要在每个测试用例里都写一遍测试装饰器功能的逻辑，这显然也违背了DRY原则。

总的来讲，我的看法依旧是装饰器与原函数应当分开测试。

然后问题就来了，我们知道装饰器在Python里其实是一个语法糖，它本质上是一个赋值操作。
比如下面的两种写法是等价的：

```python
def decorator(func):
    def wrapper(*args, **kwargs):
        print('decorated')
        return func(*args, **kwargs)
    return wrapper

# 写法一
@decorator
def foo():
    pass

# 写法二
def bar():
    pass
bar = decorator(bar)
```

像这样我们在导入函数foo的时候，它其实已经被替换掉了，我们并不能直接拿到原函数，想要对原有逻辑做测试也就无从说起了。

我在网上搜了一下，好像没有太多人有这个疑问，搜索结果和解决方案并不多。
这里以Python3为讨论前提，我大致找到了两个解决方案。

一个是stackoverflow上的一个[提问](https://stackoverflow.com/questions/30327518/how-to-unit-test-decorated-functions)，提问人的需求几乎跟我一模一样。回答里没给出啥靠谱的答案，最后提问者自己提出了一个方案，把装饰器的逻辑再拆到一个函数里，然后测试的时候对这个函数进行mock。
这个方案第一眼看过去好像确实可行，但仔细想了下，大多数情况下，装饰器里的逻辑没办法那么简单地拆分到一个函数里，每个装饰器还都得这么拆开来写，可行性较低，没做更深入的尝试（主要是立马又搜到下面这个解决方案了）。

随后在stackoverflow的另一个[提问](https://stackoverflow.com/questions/14942282/accessing-original-decorated-function-for-test-purposes)里，我得知functools的wraps会给外层wrapper提供一个`__wrapped__`属性，指向原函数。

不过在进一步搜索后，根据《Python Cookbook》提供的[说法](https://python3-cookbook.readthedocs.io/zh_CN/latest/c09/p03_unwrapping_decorator.html)，wraps提供的`__wrapped__`在遇到多层装饰器的时候，根据Python版本不同，表现并不稳定。
有些版本里它会直接指向最原始的函数，有些版本里它仅仅指向装饰器嵌套里的第二层，估计是没处理顶层的原函数也是被装饰过的情况。针对这种情况，我决定自己手动处理多层嵌套的情况，结合群友给的优化，写了个获取原始函数的函数，单元测试的时候可以拿来使用：

```python
def get_original_func(func):
	while hasattr(func, '__wrapped__'):
		func = func.__wrapped__
	return func
```

但是这种也仅仅对使用了wraps装饰器的函数有效，如果提供装饰器的人没有用到它，似乎还真没什么手段来拿到原函数了。至少我没找到什么办法，有的话欢迎探讨。

参考链接：

https://stackoverflow.com/questions/30327518/how-to-unit-test-decorated-functions

https://stackoverflow.com/questions/14942282/accessing-original-decorated-function-for-test-purposes

https://python3-cookbook.readthedocs.io/zh_CN/latest/c09/p03_unwrapping_decorator.html