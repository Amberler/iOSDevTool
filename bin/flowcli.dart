import 'dart:io';

import 'package:flowcli/util/AMConf.dart';
import 'package:flowcli/util/AMTool.dart';
import 'package:process_run/shell.dart';

void main(List<String> arguments) {
  // print('Hello world: ${flowcli.calculate()}!');
  //
  // var doc = loadYaml("YAML: YAML Ain't Markup Language");
  // print(doc['YAML']);
  // // print(AMUtil.config());
  // // print(AMUtil.path);
  // testcli();

  // AMConf.readConf().then((init) {
  //   if (init) {
  //     // 读取到配置
  //     print('已配置，验证网络');
  //     AMTool.log('已配置，验证网络');
  //   } else {
  //     // 请先配置文件
  //     AMTool.log('请先配置文件', logLevel: AMLogLevel.AMLogError);
  //   }
  // });
  //
  AMConf.checkServer().then((isOnline) {
    if (isOnline) {
      // 网络校验成功，检查配置
      print('网络校验成功');
      AMConf.readConf().then((hasConf) {
        if (hasConf) {
          // 配置校验成功，准备处理获取的组件
          print('配置校验成功，检查参数');
        } else {
          // 生成配置文件，并退出程序
          var init = AMConf.createConf();
          if (init) {
            AMTool.log('初始化成功，请打开flow.conf填写配置参数',
                logLevel: AMLogLevel.AMLogWarn);
          } else {
            AMTool.log('初始化失败，请确认是否添加执行权限', logLevel: AMLogLevel.AMLogError);
          }
        }
        exit(0);
      });
    } else {
      AMTool.log('网络校验失败，请检查是否是内网', logLevel: AMLogLevel.AMLogError);
      exit(0);
    }
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
