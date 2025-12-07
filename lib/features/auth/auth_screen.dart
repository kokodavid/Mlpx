import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/widgets/custom_button.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Milpress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Please sign in or create an account to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Sign In',
                onPressed: () {
                  // TODO: Implement sign in
                },
                isFilled: true,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Create Account',
                onPressed: () {
                  // TODO: Implement sign up
                },
                isFilled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
