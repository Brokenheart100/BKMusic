import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/auth/presentation/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController(text: "test1@qq.com");
  final _passwordController = TextEditingController(text: "123456");
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isRegister = false;
  File? _avatarFile;
  final _nicknameController = TextEditingController();

  Future<void> _pickAvatar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _avatarFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. 背景层
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF091227), Color(0xFF2E0F28)],
                ),
              ),
            ),
          ),

          // 2. 核心内容层
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  // 【修复】AnimatedContainer 需要 duration
                  duration: const Duration(milliseconds: 300),
                  width: 400,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 16),

                        // 标题
                        Text(
                          _isRegister ? "Create Account" : "Welcome Back",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 【修复】输入框区域：使用 AnimatedSize 实现平滑切换
                        // 删除了之前重复的 if (_isRegister) 块，只保留 AnimatedSize 内部的逻辑
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            children: [
                              if (_isRegister) ...[
                                _buildTextField("Nickname", _nicknameController,
                                    false, Icons.badge // 【修复】传入图标
                                    ),
                                const SizedBox(height: 16),
                              ],
                              _buildTextField("Email", _emailController, false,
                                  Icons.email // 【修复】传入图标
                                  ),
                              const SizedBox(height: 16),
                              _buildTextField("Password", _passwordController,
                                  true, Icons.lock // 【修复】传入图标
                                  ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),

                        // 登录/注册按钮
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _isRegister ? "Sign Up" : "Log In",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 切换模式按钮
                        TextButton(
                          onPressed: () =>
                              setState(() => _isRegister = !_isRegister),
                          child: Text(
                            _isRegister
                                ? "Already have an account? Log In"
                                : "Don't have an account? Sign Up",
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 头部构建：登录显示Logo，注册显示头像选择
  Widget _buildHeader(ThemeData theme) {
    if (_isRegister) {
      return GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
                image: _avatarFile != null
                    ? DecorationImage(
                        image: FileImage(_avatarFile!), fit: BoxFit.cover)
                    : null,
              ),
              child: _avatarFile == null
                  ? const Icon(Icons.add_a_photo,
                      color: Colors.white70, size: 30)
                  : null,
            ),
            if (_avatarFile != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 12, color: Colors.black),
                ),
              )
          ],
        ),
      );
    } else {
      return Icon(Icons.music_note_rounded,
          size: 64, color: theme.colorScheme.primary);
    }
  }

  // 【修复】增加了 IconData icon 参数
  Widget _buildTextField(String hint, TextEditingController controller,
      bool isPassword, IconData icon) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      validator: (value) => value == null || value.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.white54), // 使用传入的图标
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final controller = ref.read(authControllerProvider);

    try {
      if (_isRegister) {
        String? uploadedUrl;
        if (_avatarFile != null) {
          // 提示正在上传
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Uploading avatar...")));
          uploadedUrl = await controller.uploadAvatar(_avatarFile!);
        }

        // 注册 (带上头像 URL)
        await controller.register(
            _emailController.text,
            _passwordController.text,
            _nicknameController.text,
            uploadedUrl // 这里传入真实的 URL
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Success! Please log in.")));
          setState(() => _isRegister = false);
        }
      } else {
        await controller.login(
          _emailController.text,
          _passwordController.text,
        );

        // 登录成功后，不需要手动跳转
        // 这里的路由守卫 (AppRouter) 会监听到状态变化自动跳转首页
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
