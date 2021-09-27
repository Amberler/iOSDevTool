import 'dart:io';

import 'package:flowcli/util/AMTool.dart';
import 'package:flowcli/util/AMVersion.dart';
import 'package:process_run/shell.dart';

import 'AMConf.dart';

/// SVN相关操作管理类

class AMSVNManager {
  //执行shell命令工具
  static final _shellTool = Shell(verbose: false, commandVerbose: false);

  //SVN模块数据
  static late final List<String> modules;

  //通用运行命令方法
  static Future runCommand(List<String> args) async {
    var arguments = <String>[
      ...args,
      '--trust-server-cert',
      '--non-interactive',
      '--username',
      AMConf.conf.oaName,
      '--password',
      AMConf.conf.oaPasswd,
    ];

    try {
      return await _shellTool.runExecutableArguments('svn', arguments);
    } catch (e) {
      return e;
    }
  }

  //校验OA密码并获取svn仓库模块
  static Future<bool> checkOAAndGetModules() {
    var args = <String>['list', AMConf.conf.svnURL];
    // SVN校验
    try {
      return runCommand(args).then((value) {
        if (value is ProcessResult) {
          // 正常执行
          var temRes = value.stdout as String;
          var res = temRes.replaceAll('/\n', ',');
          var temList = res.split(',');
          temList.removeLast();
          modules = temList;
          return true;
        } else if (value is ShellException) {
          // 异常处理
          print('异常处理：${value.result?.stderr}');
          return false;
        } else {
          return false;
        }
      });
    } catch (e) {
      return Future.error(false);
    }
  }

  //获取指定仓库最近一次提交记录
  static Future<bool> getModuleLatestLog(
      String currentDay, String moduleName) async {
    var url = AMConf.conf.svnURL + '/' + moduleName;
    var args = ['log', '--search', currentDay, url];
    return await runCommand(args).then((value) {
      if (value is ProcessResult) {
        // 正常执行
        var date = args[2];
        String logs = value.stdout;
        // 如果日志为空，返回校验失败
        if (!logs.contains(date)) {
          return false;
        }
        // 如果日志不为空，处理日志(这里的-------个数是72个，svn日志输出就是这样，修改的话，肯定会导致截取不正常，)
        var logArr = logs.split(
            '------------------------------------------------------------------------\n');
        var resArr = [];
        for (var log in logArr) {
          if (log.isNotEmpty) {
            resArr.add(log);
          }
        }
        String latestLog = resArr.first;
        // 判断当天该用户是否提交过代码
        if (latestLog.contains(AMConf.conf.oaName)) {
          return true;
        } else {
          return false;
        }
      } else if (value is ShellException) {
        // 异常处理
        print('异常处理：${value.result?.stderr}');
        return false;
      } else {
        return false;
      }
    });
  }

  //获取模块上一次的tag记录
  static Future<String?> getModuleLatestTag(String moduleName) async {
    var url = AMConf.conf.svnURL + '/' + moduleName + '/tags';
    var args = [
      'list',
      url,
    ];
    return await runCommand(args).then((value) {
      if (value is ProcessResult) {
        var temRes = value.stdout as String;
        var res = temRes.replaceAll('/\n', ',');
        var temList = res.split(',');
        //剔除removeme.txt
        if (temList.contains('removeme.txt')) {
          temList.remove('removeme.txt');
        }
        if (temList.contains('removeme.txt\n')) {
          temList.remove('removeme.txt\n');
        }
        //剔除空字符串
        if (temList.contains('')) {
          temList.remove('');
        }
        //获取最后一个数据，判断当前版本号是正常的1.0.0还是带时间戳的1.0.0.20210909.1563
        var lastStr = temList.last;
        var lastStrList = lastStr.split('.');
        // 0:正常3位版本号,eg:1.0.1,
        // 1:带时间戳版本号,eg:2.2.0.0.20210903.1408
        var type = 0;
        var latestTag = '';
        if (lastStrList.length >= 4) {
          type = 1;
        }
        if (type == 0) {
          //  正常版本号处理 获得AMVersion的模型数组
          var versionList = temList.map((e) => AMVersion(e)).toList();
          // 模型大小排序
          versionList.sort((a, b) => a.compareTo(b));
          var resList = versionList.map((e) => e.version).toList();
          latestTag = resList.last;
        } else {
          // 带时间戳的，直接获取最后一个
          latestTag = temList.last;
        }
        // 获取最新的版本号
        return latestTag;
      } else if (value is ShellException) {
        // 异常处理
        print('异常处理：${value.result?.stderr}');
        return null;
      } else {
        return null;
      }
    });
  }

  //版本号自增逻辑
  static Future<String?> generateModuleNewTag(String moduleName) async {
    return await getModuleLatestTag(moduleName).then((lastTag) {
      if (lastTag != null) {
        //版本号新增
        var tagArr = lastTag.split('.');
        var lastStr = tagArr.last;
        var number = AMTool.isNumber(lastStr);
        if (lastStr.length >= 4) {
          if (lastStr.length == 4 && number == true) {
            //最后一个字符串刚好是四位，且为纯数字，那肯定是时分时间戳
            tagArr.removeLast();
            tagArr.last = AMTool.currentTimestamp();
          } else if (lastStr.length == 8 && number == true) {
            //最后一个字符串大于四位，认定是年月日，仅替换最后一位即可
            tagArr.last = AMTool.currentTimestamp();
          } else {
            //版本号解析失败，用户指定
            AMTool.log('获取到上一次提交的版本号为$lastTag,无法自动解析生成新版本号，请手动输入新的版本号:',
                logLevel: AMLogLevel.AMLogWarn);
            var inputTag = stdin.readLineSync();
            if (inputTag!.isEmpty) {
              AMTool.log('新的版本号不能为空', logLevel: AMLogLevel.AMLogError);
              return null;
            }
            return inputTag;
          }
        } else {
          //非时间戳版本号
          var versionParse = true;
          for (var i = tagArr.length - 1; i >= 0; i--) {
            var item = int.tryParse(tagArr[i]);
            if (item != null) {
              //版本号解析成功，自增
              if (99 - (item + 1) > 0) {
                //版本号小于99，可以自增
                tagArr[i] = (item + 1).toString();
                break;
              } else {
                //版本号大于99，
                tagArr[i] = (0).toString();
              }
            } else {
              //解析失败，分两种处理，版本号最后一位非数字，替换成当前时间戳版本号，不是最后一位非数字，终止程序
              if (i == tagArr.length - 1) {
                tagArr[i] = AMTool.currentTimestamp();
                break;
              } else {
                versionParse = false;
              }
            }
          }
          //获取到处理的版本号
          if (!versionParse) {
            return null;
          }
        }
        return tagArr.join('.');
      } else {
        return null;
      }
    });
  }

  //SVN打tag
  static Future<bool> createTag(String moduleName, String newVersion) async {
    var trunkURL = AMConf.conf.svnURL + '/' + moduleName + '/trunk';
    var targetTagURL =
        AMConf.conf.svnURL + '/' + moduleName + '/tags/' + newVersion;
    var commitLog = '$moduleName 更新 $newVersion By flowcli 小助手';

    var args = [
      'cp',
      '--pin-externals',
      trunkURL,
      targetTagURL,
      '-m',
      commitLog
    ];
    return await runCommand(args).then((value) {
      if (value is ProcessResult) {
        if (value.exitCode == 0) {
          return true;
        } else {
          AMTool.log('创建SVN Tag 失败，错误：${value.stdout}');
          return false;
        }
      } else {
        AMTool.log('创建SVN Tag 失败，请检查SVN $moduleName 仓库');
        return false;
      }
    });
  }

  //导出Podspec
  static Future<bool> getModuleOldPodspecAndGenerateNew(
      String moduleName, String newVersion) async {
    var targetTagURL = AMConf.conf.svnURL +
        '/' +
        moduleName +
        '/tags/' +
        newVersion +
        '/$moduleName.podspec';
    var args = [
      'cat',
      targetTagURL,
    ];

    return await runCommand(args).then((value) {
      if (value is ProcessResult) {
        String con = value.stdout;
        if (con.contains('version')) {
          var newPodSpec;
          var podsList = con.split('\n');
          for (var item in podsList) {
            var ret = item.contains('s.version');
            if (ret == true) {
              newPodSpec =
                  con.replaceAll(item, "  s.version          = '$newVersion'");
              break;
            }
          }
          var filePath = AMConf.conf.gitLocalPath +
              '/$moduleName/$newVersion/$moduleName.podspec';
          var file = File(filePath);

          try {
            file.createSync(recursive: true);
            file.writeAsStringSync(newPodSpec);
          } catch (error) {
            AMTool.log('$filePath 路径创建失败，请检查Git仓库路径是否正确，是否有读写权限',
                logLevel: AMLogLevel.AMLogError);
            return false;
          }
          return true;
        }
      }
      return false;
    });
  }
}
