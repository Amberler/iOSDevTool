import 'package:date_format/date_format.dart';

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
}
