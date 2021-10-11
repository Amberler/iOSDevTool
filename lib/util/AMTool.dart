import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:date_format/date_format.dart';
import 'package:flowcli/util/AMConf.dart';
import 'package:flowcli/util/AMVersion.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

/// 检测版本更新地址
var versionURL =
    'https://cdn.jsdelivr.net/gh/Amberler/iOSDevTool@main/version/version.txt';

/// 二进制更新地址
var binaryURL =
    'https://cdn.jsdelivr.net/gh/Amberler/iOSDevTool@main/version/flowcli';

/// 工具类
enum AMLogLevel {
  //绿色打印
  AMLogNormal,
  //黄色打印
  AMLogWarn,
  //红色打印
  AMLogError
}

class AMTool {
  // ignore: always_declare_return_types
  static log(String msg, {AMLogLevel? logLevel}) {
    logLevel ??= AMLogLevel.AMLogNormal;
    switch (logLevel) {
      case AMLogLevel.AMLogNormal:
        print('\x1B[36m$msg\x1B[0m');
        break;
      case AMLogLevel.AMLogWarn:
        print('\x1B[33m$msg\x1B[0m');
        break;
      case AMLogLevel.AMLogError:
        print('\x1B[31m$msg\x1B[0m');
        break;
    }
  }

  // 获取当天日期
  static String currentDay() {
    return formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd]);
  }

  // 格式化当前时间
  static String currentTimestamp() {
    return formatDate(DateTime.now(), [yyyy, mm, dd, '.', HH, nn]);
  }

  // 验证是否为数字
  static bool isNumber(String str) {
    final reg = RegExp(r'^[0-9]+.?[0-9]*$');
    return reg.hasMatch(str);
  }

  // 验证是否为数字+.(目的为了校验输入的版本号)
  static bool isNumberForVersion(String str) {
    final reg = RegExp(r'^[0-9.]*$');
    return reg.hasMatch(str);
  }

  // 版本号
  static final String version = '1.0.2';

  // 检测更新逻辑
  static Future<Map> checkVersion() async {
    try {
      var responseBody;
      var httpClient = HttpClient();
      var request = await httpClient.getUrl(Uri.parse(versionURL));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        responseBody = await response.transform(utf8.decoder).join();
        var config = loadYamlDocument(responseBody).contents.value as YamlMap;
        var currentVersion = AMVersion(version);
        var serverVersion = AMVersion(config['version']);
        var ret = currentVersion.compareTo(serverVersion);
        if (ret == -1) return {'new': true, 'version': serverVersion.version};
        return {'new': false, 'version': serverVersion.version};
      } else {
        return {'new': false, 'version': ''};
      }
    } on Exception {
      return {'new': false, 'version': ''};
    } catch (_) {
      return {'new': false, 'version': ''};
    }
  }

  // 下载程序 覆盖当前二进制
  static Future<bool> downloadBinary() async {
    var filePath = '${AMConf.executePath}/flow';
    final client = http.Client();
    try {
      var response = await client
          .send(http.Request('GET', Uri.parse(binaryURL)))
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException(
            'The connection has timed out, Please try again!');
      });
      var downloadFile = File(filePath);
      var length = response.contentLength;
      var received = 0;
      var sink = downloadFile.openWrite();

      await response.stream.map((s) {
        received += s.length;
        //输出下载进度
        _drawProgressBar((received / length!), 40);
        return s;
      }).pipe(sink);

      if (received == length) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static void _drawProgressBar(double amount, int size) {
    final limit = (size * amount).toInt();
    stdout.write(
      '\r\x1b[38;5;75;51m' +
          String.fromCharCodes(List.generate(size, (int index) {
            if (index < limit) {
              return 0x2593;
            }
            return 0x2591;
          })) +
          '\x1b[0m',
    );
  }
}
