/// 运行环境配置、校验
import 'dart:io';

class AMConf {
  //程序执行目录
  static final String executePath = Directory.current.path;

  //读取配置文件
  static Future<bool> readConf() async {
    //先判断文件是否存在
    var filePath = executePath + 'flow.conf';
    var exist = await File(filePath).exists();

    if (exist) {
      return true;
    } else {
      return false;
    }
  }

  // 网络检测
  static Future<bool> checkServer() async {
    try {
      var httpClient = HttpClient();
      var request =
          await httpClient.getUrl(Uri.parse('https://basic.hikvision.com'));
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
