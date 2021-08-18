import 'dart:io';

import 'package:flowcli/util/AMConf.dart';
import 'package:flowcli/util/AMTool.dart';
import 'package:process_run/shell.dart';

void main(List<String> arguments) {
  /// 检查环境
  checkEnvironment().then((res) {
    if (res == true) {
      // 环境配置成功
      AMTool.log('环境检测通过');
    }
    exit(0);
  });
}

Future<bool> checkEnvironment() {
  return Future.wait([AMConf.checkServer(), AMConf.readConf()]).then((res) {
    if (res[0] == true && res[1] == true) {
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
    return false;
  }).catchError((e) {
    AMTool.log('环境检测未通过', logLevel: AMLogLevel.AMLogError);
    return false;
  });
}

void testcli() async {
  var shell = Shell();
  await shell.run('''

# Display some text
echo Hello

# Display dart version
dart --version

# Display pub version
pub --version

  ''');

//   shell = shell.pushd('example');
//
//   await shell.run('''
//
// # Listing directory in the example folder
// dir
//
//   ''');
//   shell = shell.popd();
}
