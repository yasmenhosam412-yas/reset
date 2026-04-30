import 'package:new_project/features/authentication/data/datasource/remote/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient supabaseClient;

  AuthRemoteDatasourceImpl({required this.supabaseClient});
  @override
  Future<void> login({required String email, required String password}) async {
    await supabaseClient.auth.signInWithPassword(
      password: password,
      email: email,
    );
  }

  @override
  Future<void> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    await supabaseClient.auth.signUp(
      password: password,
      email: email,
      data: {"usename": username},
    );
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<void> sendPasswordRecoveryOtp({required String email}) async {
    await supabaseClient.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  @override
  Future<void> verifyOtpAndSetNewPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await supabaseClient.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
    await supabaseClient.auth.updateUser(UserAttributes(password: newPassword));
    await supabaseClient.auth.signOut();
  }
}
