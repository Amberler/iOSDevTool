import 'dart:io';

import 'package:flowcli/util/AMConf.dart';
import 'package:flowcli/util/AMGit.dart';
import 'package:flowcli/util/AMSVN.dart';
import 'package:flowcli/util/AMTool.dart';

void main(List<String> arguments) {
  AMTool.log('''
###############################################################
                                                
      ###### #       ####  #    #  ####  #      #    
      #      #      #    # #    # #    # #      #    
      #####  #      #    # #    # #      #      #    
      #      #      #    # # ## # #      #      #    
      #      #      #    # ##  ## #    # #      #    
      #      ######  ####  #    #  ####  ###### #    
                                                iOS组件发布小助手                                                            
###############################################################

命令参数说明(追加命令参数，仅支持单个模块提交，命令可以搭配组合，空格分隔)：
-f 强制提交，不校验SVN提交记录，例如 'iOSDevTool -f'，iOSDevTool解析历史版号，生成新的模块
-v 指定版本号，摈弃自动解析版本号功能，生成指定版本号，例如 'iOSDevTool -f -v 1.1.2',强制发布版本号为1.1.2的iOSDevTool组件

  ''');

  /// 检查环境
  checkEnvironment().then((res) {
    if (res == false) {
      exit(1);
    }
    checkOAAndLocalGitPath().then((res) async {
      if (res == false) {
        exit(2);
      }

      if (AMConf.conf.checkVersion) {
        /// 检测版本号
        await AMTool.checkVersion().then((map) {
          if (map['new']) {
            AMTool.log(
                '发现新版本：${map['version']}\nhttps://cdn.jsdelivr.net/gh/Amberler/iOSDevTool@main/version/flowcli\n下载替换当前二进制文件\n');
          }
        });
      }

      AMTool.log('环境检测通过,配置信息正确~~');

      /// 环境 + OA + Git 校验均通过，开始处理 组件发布流程
      /// 1.svn log 校验
      /// 2.获取组件历史版本号，生成新的版本号
      /// 3.组件打Tag
      /// 4.导出组件的Podspec，修改版本号，并在Git路径创建新的版本文件夹，导入修改后的Podspec
      /// 5.Git Push 完成 组件 发布
      ///
      AMTool.log('请输入需要打包的组件名，例如(C_OS_BeeNet):');
      var inputModules = stdin.readLineSync();
      if (inputModules!.isEmpty) {
        AMTool.log('组件名不能为空', logLevel: AMLogLevel.AMLogError);
        exit(3);
      }

      /// 判断是否包含命令参数
      if (inputModules.contains('-')) {
        await publishModuleByParams(inputModules);
        // 追加命令参数流程执行完毕，退出程序
        exit(0);
      }

      /// 处理用户输入的字符串
      var modules = handleInputModules(inputModules);
      for (var i = 0; i <= modules.length; i++) {
        var moduleName = modules[i];
        AMTool.log('\n开始处理$moduleName了', logLevel: AMLogLevel.AMLogWarn);
        // 检查现有仓库是否包含该组件
        if (AMSVNManager.modules.contains(moduleName) == false) {
          AMTool.log('现有仓库不包含$moduleName,如果是首次提交，请手动创建',
              logLevel: AMLogLevel.AMLogError);
          return;
        }
        // 检查最近提交记录是否匹配
        // 获取到组件名，SVN校验提交记录
        await AMSVNManager.getModuleLatestLog(AMTool.currentDay(), moduleName)
            .then((res) {
          if (res == false) {
            // SVN最近提交记录校验失败，退出程序
            AMTool.log('未查询到当天的提交记录，请先到SVN提交代码再尝试发布组件',
                logLevel: AMLogLevel.AMLogError);
            exit(4);
          }
          AMTool.log('$moduleName 当天提交记录匹配成功');
        });

        var newLatesVersion = '';
        //根据旧的版本号，生成新的版本号，并打Tag
        await AMSVNManager.generateModuleNewTag(moduleName).then((newVersion) {
          // 判断生成新的版本是否成
          if (newVersion == null) {
            AMTool.log('$moduleName 历史版本号解析失败，请尝试指定版本好发布',
                logLevel: AMLogLevel.AMLogError);
            exit(5);
          }
          newLatesVersion = newVersion;
        });

        // 获取到新的版本号，SVN 打 Tag
        await AMSVNManager.createTag(moduleName, newLatesVersion).then((ret) {
          if (ret == false) {
            AMTool.log('$moduleName 打Tag失败，请尝试指定版本好发布',
                logLevel: AMLogLevel.AMLogError);
            exit(6);
          } else {
            AMTool.log('$moduleName 生成新的版本成功');
          }
        });

        // // 下载PodSpec,修改版本号，并创建新的PodSpec文件
        await AMSVNManager.getModuleOldPodspecAndGenerateNew(
                moduleName, newLatesVersion)
            .then((ret) {
          if (ret == false) {
            AMTool.log('$moduleName 生成新版本PodSpec失败',
                logLevel: AMLogLevel.AMLogError);
            exit(6);
          }
          AMTool.log('$moduleName 生成新的Podspec成功');
        });

        // Git 提交新的PodSpec
        await AMGitManager.gitPush(moduleName, newLatesVersion).then((ret) {
          if (ret == true) {
            AMTool.log('$moduleName 发布成功~~');
            if (i == modules.length - 1) {
              AMTool.log('\n所有组件处理完~~');
              exit(0);
            } else {
              // 延迟2s,处理下一个
              sleep(Duration(seconds: 2));
            }
          } else {
            AMTool.log('$moduleName Git推送失败，请手动提交试试',
                logLevel: AMLogLevel.AMLogError);
            exit(7);
          }
        });
      }
    });
  });
}

/// 检查开发环境配置
Future<bool> checkEnvironment() {
  return Future.wait(
          [AMConf.checkServer(), AMConf.readConf(), AMConf.analysisConf()])
      .then((res) {
    if (res[0] == true && res[1] == true && res[2] == true) {
      return true;
    }

    AMTool.log('环境检测未通过', logLevel: AMLogLevel.AMLogError);

    if (res[0] == false) {
      AMTool.log('请检查是否连接公司内网', logLevel: AMLogLevel.AMLogError);
    }

    if (res[1] == false) {
      AMConf.createConf();
      AMTool.log('首次初始化成功，请先配置flow.conf');
    }

    if (res[2] == false) {
      AMTool.log('flow.conf配置格式不正确，解析失败', logLevel: AMLogLevel.AMLogError);
    }
    return false;
  }).catchError((e) {
    AMTool.log('环境检测未通过', logLevel: AMLogLevel.AMLogError);
    return false;
  });
}

/// 检查OA密码和本地Git路径
Future<bool> checkOAAndLocalGitPath() {
  return Future.wait(
          [AMSVNManager.checkOAAndGetModules(), AMGitManager.gitPull()])
      .then((res) {
    if (res[0] == true && res[1] == true) {
      return true;
    }

    AMTool.log('OA密码校验或者本地Git校验未通过', logLevel: AMLogLevel.AMLogError);

    if (res[0] == false) {
      AMTool.log('请检查OA用户名和密码是否正确', logLevel: AMLogLevel.AMLogError);
    }

    if (res[1] == false) {
      AMTool.log('本地Git仓库pull失败，请检查路径是否正确', logLevel: AMLogLevel.AMLogError);
    }

    return false;
  });
}

/// 处理用户输入的组件名
List<String> handleInputModules(String inputModules) {
  var modules = <String>[];
  if (inputModules.contains(',')) {
    modules = inputModules.split(',');
  } else if (inputModules.contains('，')) {
    modules = inputModules.split('，');
  } else {
    modules.add(inputModules);
  }
  return modules;
}

/// 新增追加参数发布组件功能
Future<void> publishModuleByParams(String inputModules) async {
  // 关联命令处理
  var params = inputModules.split(' ');
  var resParams = [];
  var noCheck = false;
  var specifyVersion = false;
  // 剔除空字符
  for (var param in params) {
    if (param.isNotEmpty) {
      resParams.add(param);
    }
    if (param == '-f') {
      noCheck = true;
      resParams.remove('-f');
    }
    if (param == '-v') {
      specifyVersion = true;
      resParams.remove('-v');
    }
  }

  if (resParams.isEmpty) {
    // 命令行参数有误
    AMTool.log('输入的命令行参数有误，请检查。目前仅支持 -f -v 两个可组合参数',
        logLevel: AMLogLevel.AMLogError);
    exit(100);
  }

  // 获取输入的组件名
  var moduleName = resParams.first;
  // 检查现有仓库是否包含该组件
  if (AMSVNManager.modules.contains(moduleName) == false) {
    AMTool.log('现有仓库不包含$moduleName,如果是首次提交，请手动创建',
        logLevel: AMLogLevel.AMLogError);
    return;
  }

  if (noCheck == false) {
    // 需要版本校验
    await AMSVNManager.getModuleLatestLog(AMTool.currentDay(), moduleName)
        .then((res) {
      if (res == false) {
        // SVN最近提交记录校验失败，退出程序
        AMTool.log('未查询到当天的提交记录，请先到SVN提交代码再尝试发布组件',
            logLevel: AMLogLevel.AMLogError);
        exit(4);
      }
      AMTool.log('$moduleName 当天提交记录匹配成功');
    });
  }

  var newVersion = '';
  if (specifyVersion == false) {
    //根据旧的版本号，生成新的版本号，并打Tag
    await AMSVNManager.generateModuleNewTag(moduleName)
        .then((generateNewVersion) {
      // 判断生成新的版本是否成
      if (generateNewVersion == null) {
        AMTool.log('$moduleName 历史版本号解析失败，请尝试指定版本好发布',
            logLevel: AMLogLevel.AMLogError);
        exit(5);
      }
      newVersion = generateNewVersion;
    });
  } else {
    // 指定版本提交
    newVersion = resParams.last;
  }
  // 获取到新的版本号，SVN 打 Tag
  await AMSVNManager.createTag(moduleName, newVersion).then((ret) {
    if (ret == false) {
      AMTool.log('$moduleName 打Tag失败，请尝试指定版本好发布',
          logLevel: AMLogLevel.AMLogError);
      exit(6);
    } else {
      AMTool.log('$moduleName 生成新的版本成功');
    }
  });

  // // 下载PodSpec,修改版本号，并创建新的PodSpec文件
  await AMSVNManager.getModuleOldPodspecAndGenerateNew(moduleName, newVersion)
      .then((ret) {
    if (ret == false) {
      AMTool.log('$moduleName 生成新版本PodSpec失败', logLevel: AMLogLevel.AMLogError);
      exit(6);
    }
    AMTool.log('$moduleName 生成新的Podspec成功');
  });

  // Git 提交新的PodSpec
  await AMGitManager.gitPush(moduleName, newVersion).then((ret) {
    if (ret == true) {
      AMTool.log('$moduleName 发布成功~~');
    } else {
      AMTool.log('$moduleName Git推送失败，请手动提交试试',
          logLevel: AMLogLevel.AMLogError);
      exit(7);
    }
  });
}
