/// 运行环境配置、校验
import 'dart:io';

import 'package:yaml/yaml.dart';

class AMConf {
  //程序执行目录
  static final String executePath = Directory.current.path;

  //配置文件路径
  static final String localConf = Directory.current.path + '/flow.conf';

  //配置文件
  static late final YamlMap conf;

  //配置文件检测
  static Future<bool> readConf() async {
    //先判断文件是否存在
    var exist = await File(localConf).exists();
    if (exist) {
      return true;
    } else {
      return false;
    }
  }

  //解析配置文件
  static Future<bool> analysisConf() async {
    return await File(localConf).readAsString().then((confStr) {
      conf = loadYamlDocument(confStr).contents.value as YamlMap;
      return true;
    }).catchError((e) {
      return false;
    });
  }

  //生成配置文件
  static bool createConf() {
    var conf = '''
#flow环境配置参数

OA: 
  name: 'chenxudong6'#OA账户ID
  passwd: 'Qq556677'#OA账户密码

SVN: 
  SVNModuleURL: 'https://192.0.0.140/APP-Client/iVMS5260/trunk/HiModules/iOS' #源码仓库地址，也就是组内的iOS模块仓库地址

Git: 
  PodspecPath: '/User/cxd/Dev/' #组件源码仓库本地路径，必须是Git克隆下的路径，不然没办法自动上传
   ''';
    var confFile = File(localConf);
    confFile.openWrite();
    try {
      confFile.writeAsStringSync(conf);
      return true;
    } catch (_) {
      return false;
    }
  }

  // 网络检测
  static Future<bool> checkServer() async {
    try {
      var httpClient = HttpClient();
      var request =
          await httpClient.getUrl(Uri.parse('http://oa.hikvision.com.cn'));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        return true;
      } else {
        return false;
      }
    } on Exception {
      return false;
    } catch (_) {
      return false;
    }
  }

  // SVN密码校验检测

}
