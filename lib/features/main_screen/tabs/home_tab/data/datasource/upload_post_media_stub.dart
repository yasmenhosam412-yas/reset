import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> uploadPostMediaFromLocalFile({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required String localPath,
  required FileOptions fileOptions,
}) async {
  throw UnsupportedError('Local file upload is not supported on this platform');
}
