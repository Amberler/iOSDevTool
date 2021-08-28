import 'dart:io';

import 'package:flowcli/util/AMConf.dart';
import 'package:flowcli/util/AMTool.dart';
import 'package:process_run/shell.dart';

/// Git相关操作管理类
class AMGitManager {
  //执行shell命令工具
  static final _shellTool = Shell(
      verbose: true,
      commandVerbose: true,
      workingDirectory: AMConf.conf.gitLocalPath);

  //通用执行命令工具
  static Future runCommand(List<String> arguments) async {
    try {
      return await _shellTool.runExecutableArguments('git', arguments);
    } catch (e) {
      print(e);
      return e;
    }
  }

  //拉取仓库
  static Future<bool> gitPull() async {
    var args = ['pull'];
    return await runCommand(args).then((value) {
      if (value is ProcessResult) {
        String stdout = value.stdout;
        if (stdout.contains('Already') || stdout.contains('Updating')) {
          return true;
        }
      }
      if (value is ShellException) {
        AMTool.log('Git仓库拉取失败 ：${value.message}\n${value.result?.stderr}',
            logLevel: AMLogLevel.AMLogError);
      }
      return false;
    });
  }

  //更新仓库
  static Future<bool> gitPush() async {
    var cmd = 'git add . \n git push';
    return _shellTool.run(cmd).then((value) {
      print(value);
      return false;
    }).catchError((error) {
      if (error is ShellException) {
        AMTool.log('组件Podspec 推送失败：${error.message}\n${error.result?.stderr}',
            logLevel: AMLogLevel.AMLogError);
      }
      return false;
    });
  }
}
