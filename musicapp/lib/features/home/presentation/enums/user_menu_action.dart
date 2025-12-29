import 'package:flutter/material.dart';

/// 用户菜单操作枚举
/// 使用枚举代替 String，确保类型安全，防止拼写错误
enum UserMenuAction {
  profile,
  settings,
  logout;
}

/// 使用扩展方法将 UI 属性（图标、文字、颜色）与枚举绑定
/// 这样 UI 代码会非常干净，修改样式只需改这里
extension UserMenuActionExtension on UserMenuAction {
  String get label {
    switch (this) {
      case UserMenuAction.profile:
        return 'Profile';
      case UserMenuAction.settings:
        return 'Settings';
      case UserMenuAction.logout:
        return 'Log Out';
    }
  }

  IconData get icon {
    switch (this) {
      case UserMenuAction.profile:
        return Icons.person_outline;
      case UserMenuAction.settings:
        return Icons.settings_outlined;
      case UserMenuAction.logout:
        return Icons.logout_rounded;
    }
  }

  /// 特殊颜色逻辑：注销按钮显示红色，其他白色
  Color get color {
    switch (this) {
      case UserMenuAction.logout:
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  /// 图标颜色 (通常稍微暗一点，或者跟随主色)
  Color get iconColor {
    switch (this) {
      case UserMenuAction.logout:
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }
}
