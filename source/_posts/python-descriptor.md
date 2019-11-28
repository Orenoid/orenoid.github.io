---
title: 浅谈Python函数、方法与描述符
s: python-descriptor
date: 2019-11-20 09:01:46
categories: 
- 技术
tags: [Python]
---



这两天在群里被科普了一个知识点，再一次感受到自己对Python这门语言的一无所知（当然其他语言也一样）。这里做个简单的分享。

一直以来我都以为，实例方法隐式传入self的行为是解释器级别的特殊设计，当我们调用实例方法的时候，解释器会自动传入实例对象本身，很多文章和教程也是这么写的。虽然从结果上来讲，这个说法没有太大问题，但是严格意义上来讲，解释器并没有真正执行传入`self`这个动作。隐式传入`self`这个行为，仅仅是基于描述符（descriptor）的一个通用设计而已。

<!--more-->

稍微详细点说的话，那就是Python的方法和函数其实都是function类的实例，而function类是实现了`__get__`方法的，所以它们俩其实都是描述符，在我们真正获取到方法之前（也就是拿到`__get__`返回给我们的method对象前），方法和函数没什么本质区别。

但是显然方法的行为和函数并不一样，被实例调用的时候会被隐式地自动传入self参数（这里暂且不提classmethod、staticmethod这些）。如果这不是解释器干的，这个行为是如何被实现的？

首先简单介绍下描述符的定义和作用。

一个描述器就是一个实现了三个核心的属性访问操作(get, set, delete)的类， 分别为 `__get__()` 、`__set__()` 和 `__delete__()` 这三个特殊的方法。这些方法接受一个实例作为输入，之后相应的操作实例底层的字典。

以《Python Cookbook》提供的代码为例：

```python
class Integer:
    def __init__(self, name):
        self.name = name

    def __get__(self, instance, cls):
        if instance is None:
            return self
        else:
            return instance.__dict__[self.name]

    def __set__(self, instance, value):
        if not isinstance(value, int):
            raise TypeError('Expected an int')
        instance.__dict__[self.name] = value

    def __delete__(self, instance):
        del instance.__dict__[self.name]

class Point:
    x = Integer('x')
    y = Integer('y')

    def __init__(self, x, y):
        self.x = x
        self.y = y
```

这个例子中`Integer`就是一个描述符，当作为`Point`的类属性调用时，就会触发`__get__`方法。

而正如前面提到过的，函数和方法其实本质上都是function实例。而方法自动传入self参数的行为，正是借助function类下的`__get__`方法来实现的。其实逻辑很简单，`__get__`方法接收instance和cls。当函数作为作为实例属性被获取（也就是作为方法）的时候，会触发描述符协议，通过function类的`__get__`重新获取我们的函数对象，而`__get__`内部对函数进行了处理，将接收到的instance绑定到了函数的首位参数上，效果类似于functools里的partial，然后再将处理过的函数返回。也就是说，当我们在调用实例方法的时候，本质上就是在调用一个首位参数被绑定了一个实例变量的普通函数，仅此而已。再举个简单的例子：

```python
def plus(a, b):
    return a + b

plus_two = plus.__get__(2)
plus_two(3)		# 返回 5
```

我们可以看到由`__get__`返回的新函数，参数`a`已经被固定为了2，再调用的时候只需要传入参数`b`就行了。

同时我们可以通过描述符来很方便地自定义解释器调用方法的行为，例如@classmethod、@staticmethod、@property这些装饰器实际上就是用描述符实现的。

我们可以尝试实现一个简化版的classmethod，这里假定你已经知道Python的@语法糖了。

```python
from functools import partial


class myclassmethod:
    def __init__(self, func):
        self.func = func
    def __get__(self, instance, cls=None):
        return partial(self.func, cls)
    
class Foo:
    @myclassmethod
    def bar(cls):
        print(cls)
```

当我们尝试调用`Foo.bar()`的时候，解释器做了什么呢

1. 首先是最开始的声明与定义，这个时候bar属性其实已经被包装成myclassmethod实例了
2. 装饰器尝试获取bar属性
3. 发现bar属性是个描述符，调用`__get__`方法
4. get方法返回修改了默认传参行为的新函数，也就是把第一个参数定死为cls
5. 执行`bar()`，触发callable协议，结束。

所以说这个设计的精妙之处就在于，解释器自始自终都是按照事先设计好的一套通用协议在运行，只要你提供了相应的接口，就按你的来，可谓是把鸭子类型与面向接口编程的思想发挥得淋漓尽致。