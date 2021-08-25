import 'dart:io';

import 'package:flowcli/util/AMConf.dart';
import 'package:flowcli/util/AMSVN.dart';
import 'package:flowcli/util/AMTool.dart';

void main(List<String> arguments) {
  /// 检查环境
  checkEnvironment().then((res) {
    if (res == true) {
      AMTool.log('环境检测通过');
      // 校验OA密码
      AMSVNManager.checkOAAndGetModules().then((check) {
        if (check) {
          AMTool.log('OA校验成功');

          var args = ['log', '--search', '2021-08'];

          AMSVNManager.getModuleLatestLog(args, 'C_OS_HCPBusiniessComponent');

          // exit(1);
        } else {
          AMTool.log('OA密码校验失败，请检查', logLevel: AMLogLevel.AMLogError);
          exit(0);
        }
      });
    }
  });
}

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

    // if (res[3] == false) {
    //   AMTool.log('OA密码校验失败，请检查', logLevel: AMLogLevel.AMLogError);
    // }

    return false;
  }).catchError((e) {
    AMTool.log('环境检测未通过', logLevel: AMLogLevel.AMLogError);
    return false;
  });
}
