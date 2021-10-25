# OrzOrderFile

iOS 工程二进制重排 Clang插桩方式 获取 OrderFile

## App 示例工程

一行命令，打开示例工程: 

```bash
rm -rf OrzOrderFile && git clone https://github.com/OrzGeeker/OrzOrderFile.git && cd OrzOrderFile/App && bundle && bundle exec pod install && xed .
```

## Usage

1. Podfile 中引入库依赖

```bash
pod 'OrzOrderFile', :source => 'https://github.com/OrzGeeker/Specs.git'
```

2. Podfile 中确保以下优化选项设置

```bash
install! 'cocoapods',
    :generate_multiple_pod_projects => false,
    :incremental_installation => false
```

3. Podfile 中添加 Hook 代码，参考[示例工程Podfile](./App/Podfile)内容

4. 源码编译主工程，获取全部调用符号

5. 使用iPhone的距离传感器事件，触发OrderFile文件写入和文件分享。

---

    
- 在需要将符号写入OrderFile文件中时，调用如下代码：

```objc
    [OrzOrderFile stopRecordOrderFileSymbols];
```

- 获取OrderFile文件内容，调用如下代码:

```objc
    NSString *orderFileContent = [OrzOrderFile orderFileContent];
```

- 通过AirDrop功能分享OrderFile文件到电脑上，调用如下代码:

```objc
    [OrzOrderFile shareOrderFileWithAirDrop];
```

## 参考文档

- [二进制重排原理](http://www.zyiz.net/tech/detail-127196.html)
- [二进制重排Clang插桩原理视频](https://youtu.be/9ys2iiVdcKk)
- [Clang 13 文档](https://clang.llvm.org/docs/UsersManual.html)



