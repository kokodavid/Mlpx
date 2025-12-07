import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class LoadingScreen extends StatelessWidget {
  final String message;
  final String? subMessage;

  const LoadingScreen({
    Key? key,
    required this.message,
    this.subMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/loading.gif', height: 100),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  subMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Please wait',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
