import 'package:flowcli/flowcli.dart' as flowcli;
import 'package:flowcli/util/AMConf.dart';
import 'package:flowcli/util/AMTool.dart';
import 'package:process_run/shell.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) {
  print('Hello world: ${flowcli.calculate()}!');

  var doc = loadYaml("YAML: YAML Ain't Markup Language");
  print(doc['YAML']);
  // print(AMUtil.config());
  // print(AMUtil.path);
  testcli();

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
  AMConf.checkServer().then((value) {
    if (value) {
      AMTool.log('网络校验成功');
    } else {
      AMTool.log('网络校验失败，请检查是否是内网', logLevel: AMLogLevel.AMLogError);
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
