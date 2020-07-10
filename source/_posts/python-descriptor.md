---
title: 浅谈Python函数、方法与描述符
s: python-descriptor
date: 2020-03-20 09:01:46
categories: 
- 技术
tags: [Python]
---



这两天在群里被科普了一个知识点，感觉很有意思，简单做个分享。

一直以来我都以为，实例方法隐式传入self的行为是解释器级别的特殊设计，当我们调用实例方法的时候，解释器会自动传入实例对象本身，很多文章和教程也是这么写的。虽然从结果上来讲，这个说法没有太大问题，但是严格意义上来讲，解释器并没有真正执行传入`self`这个动作。隐式传入`self`这个行为，仅仅是基于描述符（descriptor）的一个通用设计而已。

<!--more-->

我们在定义方法和函数的时候，实际上声明的都是function类的实例。而function类是实现了`__get__`方法的，所以它们俩其实都是描述符，在我们真正获取到方法之前（也就是拿到`__get__`返回给我们的method对象前），方法和函数没什么本质区别。

但是显然方法的行为和函数并不一样，被实例调用的时候会被隐式地自动传入self参数（这里暂且不提classmethod、staticmethod这些）。如果这不是解释器干的，这个行为是如何被实现的？

首先简单介绍下描述符的定义和作用。

一个描述符就是一个实现了三个核心的属性访问操作(get, set, delete)的类， 分别为 `__get__()` 、`__set__()` 和 `__delete__()` 这三个特殊的方法。

举个例子：

```python
class Bar:
   def __init__(self, value):
       self.value = value
   def __get__(self, instance, cls):
       print(f'传入实例：{instance} 传入类：{cls}')
       if instance is not None:
           print('作为实例属性调用')
           return self.value
       else:
           print('作为类属性调用')
           return 0

class Foo:
    bar = Bar(42)

Foo().bar	# 作为实例属性调用，返回self.value，即42
Foo.bar		# 作为类属性调用，instance为None，返回0
```

这个例子中`Bar`就是一个描述符，如果一个描述符被当做一个类属性来访问，那么 `instance` 参数被设置成None，作为实例属性调用的话，instance就会是那个实例本身。在`__get__`方法中就可以根据这个来判断调用形式，并决定要返回什么，比如上面的例子中，在作为类属性调用的时候会直接返回0。

明白描述符的大致工作原理后，我们回到原先的话题上，函数和方法实际上都是`function`类实例。而方法自动传入`self`参数的行为，正是借助`function`类下的`__get__`方法来实现的。

当解释器在获取类下面的一个方法（实质上是个函数）时，会触发描述符协议，先调用`function`类的`__get__`方法，`__get__`内部对函数进行了处理，会根据`instance`参数进行判断，如果不是None，也就是作为实例属性被获取，就会将接收到的`instance`绑定到函数的首位参数上（效果类似于`functools`里的`partial`），然后再将处理过的函数返回。所以，我们拿到的方法其实就是首位参数被绑定了实例变量的普通函数。而我们对它进行调用的时候，所谓的隐式传入`self`这个动作从来就没有发生过，因为它老早就被内定了。

为了加深理解，可以再来看一个简单的例子：

```python
def plus(self, b):
    return self + b
print(type(plus))	# <class 'function'>

plus_two = plus.__get__(2)
plus_two(3)		# 返回 5
```

我们可以看到由`__get__`返回的新函数，参数`self`已经被固定为了2，再调用的时候只需要传入参数`b`就行了。

基于这个设计，我们可以通过描述符来很方便地自定义解释器调用方法的行为，例如@classmethod、@staticmethod、@property这些装饰器实际上就是用描述符实现的。

我们可以尝试实现一个简化版的classmethod，这里假定你已经知道Python的@语法糖原理了。

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

Foo.bar()  # 输出：<class '__main__.Foo'>
```

当我们尝试执行上面这段代码的时候，解释器做了什么呢

1. 首先是`myclassmethod`、`Foo`两个类的声明，`Foo`类的`bar`属性会被替换为`myclassmethod`实例
2. 执行`Foo.bar()`，解释器尝试获取bar属性的时候，发现bar属性是个描述符，于是调用它的`__get__`方法
3. 在`__get__`方法中，我们通过`partial`把第一个参数固定为`cls`，返回一个新的函数。
4. 拿到新返回的函数作为`bar`属性，然后调用它，结束。实际上

实际上这里如果是执行`Foo().bar()`，输出结果也是一样的，因为在`myclassmethod`的`__get__`方法中，并没有对传入的`instance`做判断，都是直接返回`partial(self.func, cls)`，所以`bar`无论作为类属性还是实例属性获取都不会有什么区别。

最后，个人觉得Python这个设计的精妙之处就在于，解释器自始自终都是按照事先设计好的一套通用协议在运行的，只要你提供了相应的接口，那么就把相应的逻辑托管给你，提供了高度的可扩展性，可谓是把鸭子类型与面向接口编程的思想发挥得淋漓尽致。