/// 版本号解析类，比较大小

class AMVersion implements Comparable<AMVersion> {
  String version;
  AMVersion(this.version);

  @override
  int compareTo(AMVersion other) {
    var list = version.split('.');
    var otherList = other.version.split('.');
    var ret = 0;
    for (var i = 0; i < list.length; i ++){
      var item = int.tryParse(list[i]);
      var otherItem = int.tryParse(otherList[i]);
      if (item == null){
        //前者解析失败，比后者小
        ret = -1;
        break;
      }

      if (otherItem == null){
        //后者解析失败，比前者小
        ret = 1;
        break;
      }

      if(item == otherItem){
        //相等遍历下一位
        continue;
      }else{
        ret = item > otherItem ? 1 : -1;
      }
    }
    return ret;
  }

}