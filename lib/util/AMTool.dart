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
}
