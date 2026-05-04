import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/pages/home_tab.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/online_tab.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/pages/profile_tab.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/team_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeTab(),
    OnlineTab(),
    TeamTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnlineBloc>()..add(OnlineLoadRequested()),
      // [State.context] is above [BlocProvider]; use a Builder below the provider
      // for context.read<OnlineBloc>() (e.g. tab bar, dialogs).
      child: Builder(
        builder: (contextWithBloc) {
          return Scaffold(
            body: SafeArea(
              child: IndexedStack(index: _selectedIndex, children: _pages),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
                if (index == 1 || index == 2) {
                  contextWithBloc.read<OnlineBloc>().add(OnlineLoadRequested());
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.cloud_outlined),
                  selectedIcon: Icon(Icons.cloud),
                  label: 'Online',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Team',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
