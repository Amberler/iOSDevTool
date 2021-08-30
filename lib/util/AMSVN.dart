import 'dart:io';

import 'package:flowcli/util/AMTool.dart';
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
      ;
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
        if (temList.contains('removeme.txt')) {
          temList.remove('removeme.txt');
        }
        var latestTag;
        for (var i = temList.length - 1; i >= 0; i--) {
          var temItem = temList[i];
          var temTag = temItem.replaceAll('.', '');
          if (AMTool.isNumber(temTag)) {
            latestTag = temItem;
            break;
          }
        }
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
        if (lastStr.length >= 4 && number == true) {
          //时间戳版本号
          tagArr.removeLast();
          tagArr.last = AMTool.currentTimestamp();
        } else {
          //非时间戳版本号
          var versionParse = true;
          for (var i = tagArr.length - 1; i >= 0; i--) {
            var item = int.tryParse(tagArr[i]);
            if (item != null) {
              //版本号解析成功，自增
              if (9 - (item + 1) > 0) {
                //版本号+9，可以自增
                tagArr[i] = (item + 1).toString();
                break;
              } else {
                //版本号大于9，
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
