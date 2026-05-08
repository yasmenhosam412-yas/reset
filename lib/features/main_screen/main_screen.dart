import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/navigation/main_shell_controller.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/pages/home_tab.dart';
import 'package:new_project/features/main_screen/tabs/notifications_tab/notifications_tab.dart';
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
  late final MainShellController _mainShell;
  BuildContext? _blocSubtreeContext;

  static const List<Widget> _pages = [
    HomeTab(),
    OnlineTab(),
    NotificationsTab(),
    TeamTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _mainShell = getIt<MainShellController>();
    _mainShell.addListener(_onMainShellIntent);
  }

  @override
  void dispose() {
    _mainShell.removeListener(_onMainShellIntent);
    super.dispose();
  }

  void _onMainShellIntent() {
    final tab = _mainShell.takePendingTabIndex();
    if (tab != null && tab >= 0 && tab < _pages.length && mounted) {
      setState(() => _selectedIndex = tab);
      if (tab == 1 || tab == 2 || tab == 3) {
        _blocSubtreeContext?.read<OnlineBloc>().add(OnlineLoadRequested());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<OnlineBloc>()..add(OnlineLoadRequested()),
      child: Builder(
        builder: (contextWithBloc) {
          _blocSubtreeContext = contextWithBloc;
          return Scaffold(
            body: SafeArea(
              child: IndexedStack(index: _selectedIndex, children: _pages),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
                if (index == 1 || index == 2 || index == 3) {
                  contextWithBloc.read<OnlineBloc>().add(OnlineLoadRequested());
                }
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: l10n.posts,
                ),
                NavigationDestination(
                  icon: Icon(Icons.cloud_outlined),
                  selectedIcon: Icon(Icons.cloud),
                  label: l10n.online,
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: l10n.alerts,
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: l10n.battles,
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: l10n.profile,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
