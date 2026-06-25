import 'dart:io';
import 'dart:typed_data';

Future<String> saveCouponImageBytes(Uint8List bytes, String fileName) async {
  final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final candidates = <Directory>[
    if (Platform.isAndroid) Directory('/storage/emulated/0/Pictures/ViyafaariTown'),
    Directory('${Directory.systemTemp.path}/ViyafaariTown'),
  ];

  String lastError = '';
  for (final directory in candidates) {
    try {
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      final file = File('${directory.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (error) {
      lastError = error.toString();
    }
  }

  throw FileSystemException('Could not save coupon image. $lastError', safeName);
}
