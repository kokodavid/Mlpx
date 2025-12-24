import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/widgets/audio_play_button.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/providers/audio_session_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_strings.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the audio session state for this screen
    final audioState = ref.watch(audioSessionProvider.notifier).getScreenAudioState('welcome_screen');

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const AudioPlayButton(
                        screenId: 'welcome_screen',
                        lottieAsset: 'assets/waveworm.json',
                        audioStoragePath: 'welcome.mp3',
                        backgroundColor: AppColors.successColor,
                        showReplayButton: true,
                        showClearCacheButton: true,
                      ),
                      
                      // Audio status indicator
                      const SizedBox(height: 8),
                      if (audioState.isCached)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Audio Ready',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  AppStrings.learnAnytime,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppStrings.buildHabit,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/welcome_illustration.png',
                    height: MediaQuery.of(context).size.height * 0.33,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      text: AppStrings.getStarted,
                      onPressed: () async {
                        // Stop audio session before navigating
                        await ref.read(audioSessionProvider.notifier).stopSession('welcome_screen');
                        context.go('/course-prep');
                      },
                      isFilled: true,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: AppStrings.alreadyHaveAccount,
                      onPressed: () async {
                        // Stop audio session before navigating
                        await ref.read(audioSessionProvider.notifier).stopSession('welcome_screen');
                        context.go('/signup');
                      },
                      isFilled: false,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
