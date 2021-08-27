import 'dart:io';

import 'package:flowcli/util/AMTool.dart';
import 'package:process_run/shell.dart';

import 'AMConf.dart';

class AMSVNManager {
  //执行shell命令工具
  static final _shellTool = Shell(verbose: true, commandVerbose: false);

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
      print(e);
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
        // 如果日志不为空，处理日志(这里的-------个数是72个，svn日志输出就是这样，修改的话，可能会导致截取不正常，)
        var logArr = logs.split(
            '------------------------------------------------------------------------\n');
        var resArr = [];
        for (var log in logArr) {
          if (log.isNotEmpty) {
            resArr.add(log);
          }
        }
        String latestLog = resArr.first;
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
        print(temList.length);
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

  static Future<String> generateModuleNewTag(String moduleName) async {
    return await getModuleLatestTag(moduleName).then((lastTag) {
      if (lastTag != null) {
        //版本号新增

        var str = '1.99.99qwe';

        var tagArr = str.split('.');
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
              if (99 - (item + 1) > 0) {
                //版本号+1小于99，可以自增
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
                print('版本号解析失败');
                versionParse = false;
              }
            }
          }

          //获取到处理的版本号
          if (!versionParse) {
            print('版本号解析失败');
          }
        }
        print('处理后的版本号：${tagArr.join('.')}');
        return '';
      } else {
        return '';
      }
    });
  }

  //SVN打tag
  static void createTag(String moduleName) {
    var args = [
      'cp',
      '--pin-externals',
    ];
  }
}
