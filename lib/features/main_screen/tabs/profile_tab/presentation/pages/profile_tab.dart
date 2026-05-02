import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_bloc.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_event.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/pages/profile_tab_view.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(ProfileLoadRequested()),
      child: const ProfileTabView(),
    );
  }
}
