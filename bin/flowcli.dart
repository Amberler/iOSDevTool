import 'package:flowcli/flowcli.dart' as flowcli;

import 'package:yaml/yaml.dart';
// import 'package:florcli/util/util.dart';
import 'dart:async';
import 'package:process_run/shell.dart';

void main(List<String> arguments) {
  print('Hello world: ${flowcli.calculate()}!');

  var doc = loadYaml("YAML: YAML Ain't Markup Language");
  print(doc['YAML']);
  // print(AMUtil.config());
  // print(AMUtil.path);
  testcli();

}

void testcli() async{
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

