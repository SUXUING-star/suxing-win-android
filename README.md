# 介绍(intro.)
这是我的一个独立开发的项目，基于flutter开发的跨平台应用。

**目前正在奋力开发ing.......**
~~快了快了~~

**宿星茶会**，打造一个分享与交流galgame的平台。


**Windows版下载**  **Android版下载**

~~ios不打算弄了，要缴纳皇帝税弄不了~~

web版出于js十分垃圾的安全机制不想再额外开发web版了，如果开发web线路需要额外考虑各种安全机制。。。

（web版有打算用severless来做一个新的）

曾经的网页版：[宿星茶会](https://www.suxing.site/)

预定发布页: [发布页（测试）](https://xingsu.fun/)

# 使用(using)

windows版和android版都以压缩包形式存储了，你需要解压打开使用，

**注意windows你需要连同整个压缩包解压出来使用，如果在解压工具里打开可能会报错。**

Android版并没有经过其他平台分发，仅在此处发布，使用手机进行安装请自行接受风险警告。

# 关于源码（source）

由于本项目属于客户端开发，出于安全考虑，部分服务层代码暂不开放,因为涉及加密和安全机制的问题。

本项目的大致架构如下

Flutter(ui层&服务端交互层&本地缓存)-->Go(实际业务处理层&redis等缓存处理)-->Mongodb

(Flutter构建Windows底层是cpp文件构建，main.cpp会启动flutter应用。

构建Android底层是kotlin&java文件,mainactity.kt会启动flutter应用)

如果你想要研究本项目的源码，你需要拥有以下配置
```json
{
    "server1": "..., //服务端(go/nodejs/java...)",
    "server2": "..., //其他代理服务",
    "email": { 
      "...":"xxxx"
    },
    "github": { 
      "name": "... ,//github名字",
      "repo": "...,//github仓库"
    }
}
```
除上述配置之外，你还需要有应用打包的安全配置，如加密配置等。

ui构建基本都是flutter原装的ui，有些需要复用的做了封装。


















