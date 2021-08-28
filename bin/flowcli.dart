import 'dart:io';

import 'package:flowcli/util/AMConf.dart';
import 'package:flowcli/util/AMGit.dart';
import 'package:flowcli/util/AMSVN.dart';
import 'package:flowcli/util/AMTool.dart';

void main(List<String> arguments) {
  /// 检查环境
  checkEnvironment().then((res) {
    if (res == false) {
      exit(1);
    }
    checkOAAndLocalGitPath().then((res) {
      if (res == false) {
        exit(2);
      }

      /// 环境 + OA + Git 校验均通过，开始处理 组件发布流程
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
