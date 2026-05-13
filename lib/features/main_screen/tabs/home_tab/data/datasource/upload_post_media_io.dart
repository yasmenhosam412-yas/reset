import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> uploadPostMediaFromLocalFile({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required String localPath,
  required FileOptions fileOptions,
}) async {
  final f = File(localPath);
  if (!await f.exists()) {
    throw StateError('Media file missing');
  }
  await client.storage.from(bucket).upload(objectPath, f, fileOptions: fileOptions);
}
