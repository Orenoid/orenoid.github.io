---
title: JS Curry
date: 2017-08-30 16:32:15
tags:
---

偶然在网上看到一条题目，要求实现一个add函数满足：
```
console.log(add(2)(3));     // 5
console.log(add(3)(3)(3));  // 9
```

第一反应自然是闭包，因为要持续反复调用，返回的应当是函数，但最后要返回的又是数字，所以调用次数不确定这一点卡住我了，不知道应该如何设计这个闭包。  
上网查了下答案，大概弄明白了，以下是函数的代码：
```
function add(x) {
    var sum = x;
    var tmp = function(y) {
        sum += y;
        return tmp;
    }
    tmp.toString = function () {
        return sum;
    }
    return tmp;
}
```
关键在于题目要求的是用console.log打印出结果，而在打印的时候会调用Function的toString方法。这个闭包很巧妙的利用console.log来判定是否已经结束运算，并将sum储存在toString方法里，一旦被调用就将其返回。

[参考](https://segmentfault.com/q/1010000008323101/a-1020000008323911)

随后我在评论里看到有人提到了Curry化，遂作搜索，又名柯里化，大概扫了一眼，原来是函数式编程的东西。好吧，又是函数式编程。