import 'package:flutter/material.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:milpress/services/biometric_service.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/on_boarding/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:go_router/go_router.dart';
import 'package:milpress/features/assessment/providers/assessment_result_provider.dart';
import 'package:milpress/features/assessment/services/assessment_result_service.dart';
import 'package:milpress/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:milpress/services/data_clear_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;
  final BiometricService _biometricService = BiometricService();
  final _supabase = Supabase.instance.client;
  final _dio = Dio();
  final AssessmentResultService _assessmentResultService = AssessmentResultService();

  @override
  void initState() {
    super.initState();
    try {
      _initializeApp();
    } catch (e, stackTrace) {
      developer.log('Error in initState: $e\n$stackTrace');
      // If initialization fails, try to navigate to welcome screen
      if (mounted) {
        Future.delayed(Duration.zero, () {
          context.go('/welcome');
        });
      }
    }
  }

  Future<void> _preloadAudioFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      
      // Define audio files to preload with their storage buckets
      final audioFiles = [
        {'bucket': 'assessment-sounds', 'path': 'welcome.mp3'},
        {'bucket': 'assessment-sounds', 'path': 'assesment.mp3'},
      ];

      for (var audioFile in audioFiles) {
        try {
          final localFilePath = '${dir.path}/${audioFile['path']}';
          final file = File(localFilePath);

          // Check if file is already cached
          if (!await file.exists()) {
            // Get the public URL from Supabase storage
            final audioUrl = _supabase.storage
                .from(audioFile['bucket']!)
                .getPublicUrl(audioFile['path']!);

            developer.log('Attempting to download: $audioUrl');

            // Download and cache the file in the background
            _dio.download(
              audioUrl,
              localFilePath,
              onReceiveProgress: (received, total) {
                if (total != -1) {
                  final progress = (received / total * 100).toStringAsFixed(0);
                  developer.log('Downloading ${audioFile['path']}: $progress%');
                }
              },
            ).catchError((error) {
              developer.log('Error downloading ${audioFile['path']}: $error');
            });
          } else {
            developer.log('File already exists: ${audioFile['path']}');
          }
        } catch (e) {
          developer.log('Error processing audio file ${audioFile['path']}: $e');
          // Continue with next file even if one fails
          continue;
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error in _preloadAudioFiles: $e\n$stackTrace');
    }
  }

  Future<void> _showBiometricSetupSheet() async {
    if (!mounted) return;

    try {
      final isBiometricAvailable = await _biometricService.isBiometricAvailable();
      if (!isBiometricAvailable) {
        if (mounted) {
          context.go('/');
        }
        return;
      }

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext sheetContext) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fingerprint,
                size: 64,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enable Biometric Login',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Secure your account with biometric authentication for quick and easy access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context.go('/');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        try {
                          final authenticated = await _biometricService.authenticate();
                          if (authenticated) {
                            await _biometricService.enableBiometrics();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Biometric login enabled successfully!')),
                              );
                              context.go('/');
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Biometric authentication failed. Please try again.')),
                              );
                              context.go('/');
                            }
                          }
                        } catch (e) {
                          developer.log('Biometric setup failed: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to setup biometrics: $e')),
                            );
                            context.go('/');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Enable',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      developer.log('Error showing biometric setup sheet: $e');
      if (mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _checkAndClearDataOnFreshInstall() async {
    try {
      final isFirstRun = await DataClearService.isFreshInstallation();
      
      if (isFirstRun) {
        developer.log('Fresh installation detected. Clearing all persistent data...');
        
        // Clear all persistent data
        await DataClearService.clearAllData();
        
        // Mark as not first run
        await DataClearService.markAsNotFreshInstallation();
        
        developer.log('All persistent data cleared successfully');
      } else {
        developer.log('Not a fresh installation, keeping existing data');
      }
    } catch (e, stackTrace) {
      developer.log('Error in _checkAndClearDataOnFreshInstall: $e\n$stackTrace');
      // Continue with app initialization even if clearing fails
    }
  }

  Future<void> _initializeApp() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // Check for fresh installation and clear data if needed
      await _checkAndClearDataOnFreshInstall();
      
      // Start audio preloading in the background
      _preloadAudioFiles();
      
      // Always wait for 3 seconds on splash screen
      await Future.delayed(const Duration(seconds: 3));
      
      if (!mounted) return;
      
      // Get current user from Supabase
      final user = SupabaseConfig.currentUser;
      
      if (user != null) {
        try {
          // Check if biometrics are enabled
          final isBiometricEnabled = await _biometricService.isBiometricEnabled();
          
          if (isBiometricEnabled) {
            // If biometrics are enabled, authenticate
            final authenticated = await _biometricService.authenticate();
            if (!authenticated) {
              // If authentication fails, go to login
              if (mounted) {
                context.go('/login');
              }
              return;
            }
            // If authenticated, go to home
            if (mounted) {
              context.go('/');
            }
          } else {
            // If biometrics are not enabled, show setup sheet
            await _showBiometricSetupSheet();
          }
        } catch (e, stackTrace) {
          developer.log('Error during biometric check: $e\n$stackTrace');
          // On error, still go to home if user exists (don't redirect to login)
          if (mounted) {
            context.go('/');
          }
        }
      } else {
        // If not authenticated, check if guest user has completed assessment
        try {
          final hasCompletedAssessment = await _assessmentResultService.hasCompletedAssessment();
          if (hasCompletedAssessment) {
            // Guest user has completed assessment, set guest mode and go directly to home
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_guest_user', true);
            if (mounted) {
              context.go('/');
            }
          } else {
            // Guest user hasn't completed assessment, go to welcome
            if (mounted) {
              context.go('/welcome');
            }
          }
        } catch (e) {
          developer.log('Error checking assessment completion: $e');
          // On error, go to welcome as fallback
          if (mounted) {
            context.go('/welcome');
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error during initialization: $e\n$stackTrace');
      if (mounted) {
        context.go('/welcome');
      }
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/orange_logo.png',
          width: 150,
          height: 150,
          errorBuilder: (context, error, stackTrace) {
            developer.log('Error loading logo: $error\n$stackTrace');
            return const Icon(
              Icons.error_outline,
              size: 150,
              color: Colors.red,
            );
          },
        ),
      ),
    );
  }
}
