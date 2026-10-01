import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/dashboard/district_dashboard_view.dart';
import '../views/dashboard/school_dashboard_view.dart';
import '../views/schools/school_list_view.dart';
import '../views/students/student_list_view.dart';
import '../views/students/student_detail_view.dart';
import '../views/attendance/attendance_view.dart';
import '../views/fees/fees_view.dart';
import '../views/exams/exams_view.dart';
import '../views/risk/risk_alerts_view.dart';
import '../views/settings/settings_view.dart';
import '../providers/app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authState.value;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') || state.matchedLocation.startsWith('/register');

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterView(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // District Dashboard Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DistrictDashboardView(),
                routes: [
                  GoRoute(
                    path: 'district/:districtId',
                    name: 'district-detail',
                    builder: (context, state) => DistrictDashboardView(
                      districtId: state.pathParameters['districtId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Schools Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schools',
                name: 'schools',
                builder: (context, state) => const SchoolListView(),
                routes: [
                  GoRoute(
                    path: ':schoolId',
                    name: 'school-detail',
                    builder: (context, state) => SchoolDetailView(
                      schoolId: state.pathParameters['schoolId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'students',
                        name: 'school-students',
                        builder: (context, state) => StudentListView(
                          schoolId: state.pathParameters['schoolId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'attendance',
                        name: 'school-attendance',
                        builder: (context, state) => AttendanceView(
                          schoolId: state.pathParameters['schoolId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'fees',
                        name: 'school-fees',
                        builder: (context, state) => FeesView(
                          schoolId: state.pathParameters['schoolId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'exams',
                        name: 'school-exams',
                        builder: (context, state) => ExamsView(
                          schoolId: state.pathParameters['schoolId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'risk',
                        name: 'school-risk',
                        builder: (context, state) => RiskAlertsView(
                          schoolId: state.pathParameters['schoolId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Students Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/students',
                name: 'all-students',
                builder: (context, state) => const StudentListView(),
                routes: [
                  GoRoute(
                    path: ':studentId',
                    name: 'student-detail',
                    builder: (context, state) => StudentDetailView(
                      studentId: state.pathParameters['studentId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Risk & Alerts Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/risk',
                name: 'risk-overview',
                builder: (context, state) => const RiskAlertsView(),
              ),
            ],
          ),
          // Settings Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Schools',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Risk',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}