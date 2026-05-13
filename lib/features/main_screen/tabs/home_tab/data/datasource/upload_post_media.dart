import 'package:supabase_flutter/supabase_flutter.dart';

import 'upload_post_media_stub.dart'
    if (dart.library.io) 'upload_post_media_io.dart' as impl;

Future<void> uploadPostMediaFromLocalFile({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required String localPath,
  required FileOptions fileOptions,
}) =>
    impl.uploadPostMediaFromLocalFile(
      client: client,
      bucket: bucket,
      objectPath: objectPath,
      localPath: localPath,
      fileOptions: fileOptions,
    );
