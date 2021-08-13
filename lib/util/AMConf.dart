/// 运行环境配置、校验
import 'dart:io';

class AMConf {
  //程序执行目录
  static final String executePath = Directory.current.path;

  //配置文件
  static final String localConf = Directory.current.path + '/flow.conf';

  //读取配置文件
  static Future<bool> readConf() async {
    //先判断文件是否存在
    var exist = await File(localConf).exists();
    if (exist) {
      return true;
    } else {
      return false;
    }
  }

  //生成配置文件
  static bool createConf() {
    var conf = '''
    #OA相关
    [app]
    OAName            = "" #OA的用户ID,例如张三19的为zhangsan19
    OAPasswd          = "" #OA对应密码,密码修改请务必更新
    
    #SVN相关
    [Git]
    SVNModuleURL      = "https://192.0.0.140/APP-Client/iVMS5260/trunk/HiModules/iOS" #源码仓库地址，也就是组内的iOS模块仓库地址
    
    #Git相关
    [Git]
    PodspecPath       = "" #组件源码仓库本地路径，必须是Git克隆下的路径，不然没办法自动上传
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
}
