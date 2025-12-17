import 'package:flutter/material.dart';
import 'package:src_app/screens/admin/policies/admin_policy_screen.dart';
import 'package:src_app/screens/admin/study_packs/admin_study_packs_screen.dart';
import 'package:src_app/screens/card/flashcard_screen.dart';
import 'package:src_app/screens/home/home_screen.dart';
import 'package:src_app/screens/payment/upgrade_premium_screen.dart';
import '../models/class_model.dart';
import '../screens/admin/users/admin_user_management_screen.dart';
import '../screens/admin/policies/admin_policy_create_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/forgot_otp_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/card/flashcard_creation_screen.dart';
import '../screens/category/class_category_flashcards_screen.dart';
import '../screens/class/add_members_screen.dart';
import '../screens/class/class_categories_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/setting/settings_screen.dart';
import '../screens/setting/change_password_screen.dart';
import '../screens/statistics/study_statistics_screen.dart';
import '../screens/payment/usage_limit_screen.dart';
import '../screens/admin/dashboard/admin_home_screen.dart';
import '../screens/payment/invoices_screen.dart';
import '../screens/auth/terms_privacy_screen.dart';

import '../screens/class/teacher_class_management_screen.dart';
import '../screens/class/class_detail_screen.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgot = '/forgot';
  static const String forgot_otp = '/forgot_otp';
  static const String reset_password = '/reset_password';
  static const String home = '/home';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String setting = '/setting';
  static const String change_password = '/change_password';
  static const String study_statistics = '/study_statistics';
  static const String usage_limit = '/usage_limit';
  static const String upgrade_premium = '/upgrade_premium';
  static const String payment = '/payment';
  static const String pay_later = '/pay_later';
  static const String invoices = '/invoices';
  static const String invoice_detail = '/invoice_detail';
  static const String terms_privacy = '/terms_privacy';
  static const String flashcard = '/flashcard';
  static const String flashcard_creation = '/flashcard_creation';

  static const String teacher_classes = '/teacher_classes';
  static const String class_detail = '/class_detail';
  static const String join_class = '/join_class';
  static const String class_management = '/class_management';

  static const String classCategories = '/class-categories';
  static const String classCategoryFlashcards = '/class-category-flashcards';
  static const String addMembers = '/add-members';
  static const String admin_home = '/admin_home';
  static const String admin_users_management = '/admin_users_management';
  static const String admin_study_packs = '/admin_study_packs';
  static const String admin_policy = '/admin_policy';
  static const String admin_policy_create = '/admin_policy_create';

  static Map<String, WidgetBuilder> routes = {
    welcome: (context) => const WelcomeScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    otp: (context) => const OtpScreen(),
    forgot: (context) => const ForgotPasswordScreen(),
    forgot_otp: (context) => const ForgotOtpScreen(),
    reset_password: (context) => const ResetPasswordScreen(),
    home: (context) => const HomeScreen(),
    search: (context) => const SearchScreen(),
    profile: (context) => const ProfileScreen(),
    setting: (context) => const SettingsScreen(),
    change_password: (context) => const ChangePasswordScreen(),
    study_statistics: (context) => const StudyStatisticsScreen(),
    usage_limit: (context) => const UsageLimitScreen(),
    upgrade_premium: (context) => const UpgradePremiumScreen(),
    invoices: (context) => const InvoicesScreen(),
    terms_privacy: (context) => const TermsPrivacyScreen(),
    flashcard: (context) => FlashcardScreen(),
    flashcard_creation: (context) => const FlashcardCreationScreen(),

    teacher_classes: (context) => const TeacherClassManagementScreen(),
    // class_management: (context) => const ClassManagementScreen(),

    admin_home: (context) => const AdminHomeScreen(),
    admin_users_management: (context) => const AdminUserManagementScreen(),
    admin_study_packs: (context) => const AdminStudyPacksScreen(),
    admin_policy: (context) => const AdminPolicyScreen(),
    admin_policy_create: (context) => const AdminPolicyCreateScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case class_detail:
        final classId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ClassDetailScreen(classId: classId),
        );

      // case join_class:
      //   final prefilledCode = settings.arguments as String?;
      //   return MaterialPageRoute(
      //     builder: (_) => JoinClassScreen(prefilledCode: prefilledCode),
      //   );

      case classCategories:
        final classModel = settings.arguments as ClassModel;
        return MaterialPageRoute(
          builder: (_) => ClassCategoriesScreen(classModel: classModel),
        );

      case classCategoryFlashcards:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ClassCategoryFlashcardsScreen(
            category: args['category'],
            classModel: args['classModel'],
          ),
        );

      // case addMembers:
      //   final classModel = settings.arguments as ClassModel;
      //   return MaterialPageRoute(
      //     builder: (_) => AddMembersScreen(classModel: classModel),
      //   );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }


}