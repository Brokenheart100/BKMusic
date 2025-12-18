import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:music_app/objectbox.g.dart'; // 生成的文件

class ObjectBoxManager {
  late final Store store;

  // 私有构造函数
  ObjectBoxManager._create(this.store);

  static Future<ObjectBoxManager> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // 在文档目录下创建一个名为 'music-db' 的文件夹
    final store = openStore(directory: p.join(docsDir.path, "music-db"));
    return ObjectBoxManager._create(await store);
  }
}
