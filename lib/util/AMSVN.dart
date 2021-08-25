import 'dart:io';

import 'package:process_run/shell.dart';

import 'AMConf.dart';

class AMSVNManager {
  //执行shell命令工具
  static final _shellTool = Shell(verbose: true);

  //SVM模块数据
  static late final List<String> modules;

  //通用运行命令方法
  static Future runCommand(List<String> args, {String? module}) async {
    var url;
    if (module != null) {
      url = AMConf.conf['SVN']['SVNModuleURL'] + '/' + module;
    } else {
      url = AMConf.conf['SVN']['SVNModuleURL'];
    }

    var arguments = <String>[
      ...args,
      '--trust-server-cert',
      '--non-interactive',
      url,
      '--username',
      AMConf.conf['OA']['name'],
      '--password',
      AMConf.conf['OA']['passwd'],
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
    var args = <String>['list'];
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
  static void getModuleLatestLog(List<String> args, String moduleName) {
    runCommand(args, module: moduleName).then((value) => print(value));
  }
}
