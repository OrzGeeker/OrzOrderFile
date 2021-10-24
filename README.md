# OrzOrderFile

iOS 工程二进制重排 Clang插桩方式 获取 OrderFile

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

3. Podfile 中添加下面 Hook 代码

```bash
def custom_target_build_settings(target)
  target.build_configurations.each do |build_configuration|
    # for objective-c
    other_cflags = build_configuration.build_settings['OTHER_CFLAGS']
    build_configuration.build_settings['OTHER_CFLAGS'] = ['$(inherited)',other_cflags, '-fsanitize-coverage=func,trace-pc-guard'].flatten.uniq.compact
    # for swift
    other_swift_flags = build_configuration.build_settings['OTHER_SWIFT_FLAGS']
    if other_swift_flags.is_a?(String)
      other_swift_flags = other_swift_flags.split("\s").uniq
    end
    build_configuration.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)',other_swift_flags, '-sanitize-coverage=func,trace-pc-guard','-sanitize=undefined'].flatten.uniq.compact
  end
end

post_install do |installer|

  # 改变主工程设置
  installer.aggregate_targets.each do |aggregate_target|
    project_path = aggregate_target.user_project.path
    project = Xcodeproj::Project.open(project_path)
    project.targets.each do |target|
      # 只有主工程添加，扩展Target不添加
      unless target.extension_target_type?
        custom_target_build_settings(target)
      end
    end
    project.save
  end
  
  # 改变所有pods的设置
  installer.pods_project.targets.each do |target|
    custom_target_build_settings(target)
  end
  
end
```

4. 源码编译主工程，获取全部调用符号
    - 使用iPhone的距离传感器，决定是否写入文件。
    - 用手遮住距离传感器，黑屏时写入文件。
    - 不遮挡距离传感器，从黑屏转为亮屏时，使用AirDrop分享orderFile文件到电脑

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

## App 示例工程

下面的命令行，展示如何安装示例App运行环境，及打开项目文件：

```bash
$ bundle
Fetching gem metadata from https://rubygems.org/.......
Fetching rexml 3.2.5
...
Bundle complete! 2 Gemfile dependencies, 37 gems now installed.
Bundled gems are installed into `./vendor/bundle`
$ bundle exec pod install && xed .
```

## 参考文档

- [二进制重排原理](http://www.zyiz.net/tech/detail-127196.html)
- [二进制重排Clang插桩原理视频](https://youtu.be/9ys2iiVdcKk)
- [Clang 13 文档](https://clang.llvm.org/docs/UsersManual.html)



