// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'lesson_history_screen.dart';
// import 'bookmarks_screen.dart';
// import 'providers/lesson_history_provider.dart';
// import 'providers/bookmark_provider.dart';
// import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';
// import 'package:milpress/features/lesson/providers/lesson_download_provider.dart';
// import 'downloaded_lessons_screen.dart';

// // Sync state provider to manage syncing state
// class SyncState {
//   final bool isSyncing;
//   final String? message;
//   final bool isSuccess;
//   final bool isError;

//   SyncState({
//     this.isSyncing = false,
//     this.message,
//     this.isSuccess = false,
//     this.isError = false,
//   });

//   SyncState copyWith({
//     bool? isSyncing,
//     String? message,
//     bool? isSuccess,
//     bool? isError,
//   }) {
//     return SyncState(
//       isSyncing: isSyncing ?? this.isSyncing,
//       message: message ?? this.message,
//       isSuccess: isSuccess ?? this.isSuccess,
//       isError: isError ?? this.isError,
//     );
//   }
// }

// class SyncStateNotifier extends StateNotifier<SyncState> {
//   SyncStateNotifier() : super(SyncState());

//   Future<void> startSync() async {
//     state = state.copyWith(isSyncing: true, message: null, isSuccess: false, isError: false);
//   }

//   void setSuccess(String message) {
//     state = state.copyWith(
//       isSyncing: false,
//       message: message,
//       isSuccess: true,
//       isError: false,
//     );
//   }

//   void setError(String message) {
//     state = state.copyWith(
//       isSyncing: false,
//       message: message,
//       isSuccess: false,
//       isError: true,
//     );
//   }

//   void reset() {
//     state = SyncState();
//   }
// }

// final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
//   return SyncStateNotifier();
// });

// class ReviewScreen extends ConsumerStatefulWidget {
//   const ReviewScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
// }

// class _ReviewScreenState extends ConsumerState<ReviewScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Force refresh of all progress-related providers when screen opens
//     // This ensures we always show the most up-to-date sync status
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.invalidate(unsyncedLessonsProvider);
//       ref.invalidate(lessonHistoryProvider);
//       ref.invalidate(bookmarkCountProvider);
//       ref.invalidate(downloadedLessonIdsProvider);
//       ref.invalidate(downloadedLessonsCountProvider);
//       // Reset sync state when screen opens
//       ref.read(syncStateProvider.notifier).reset();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Fetch real lesson history count
//     final lessonHistoryAsync = ref.watch(lessonHistoryProvider);
//     int historyCount = 0;
//     if (lessonHistoryAsync is AsyncData && lessonHistoryAsync.value != null) {
//       historyCount = lessonHistoryAsync.value!.length;
//     }
//     // Unsynced lessons
//     final unsyncedLessonsAsync = ref.watch(unsyncedLessonsProvider);
//     // Bookmark count
//     final bookmarkCountAsync = ref.watch(bookmarkCountProvider);
//     // Sync state
//     final syncState = ref.watch(syncStateProvider);
//     // Downloaded lessons count
//     final downloadedLessonsAsync = ref.watch(downloadedLessonsCountProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F8F8),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 16),
//                 // Header
//                 const Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Review',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF232B3A),
//                       ),
//                     ),
//                     // Row(
//                     //   children: [
//                     //     Container(
//                     //       margin: const EdgeInsets.only(right: 12),
//                     //       decoration: BoxDecoration(
//                     //         shape: BoxShape.circle,
//                     //         border: Border.all(color: Colors.orange.shade200),
//                     //         color: Colors.white,
//                     //       ),
//                     //       padding: const EdgeInsets.all(8),
//                     //       child: const Icon(
//                     //         Icons.local_fire_department,
//                     //         color: Colors.orange,
//                     //         size: 22,
//                     //       ),
//                     //     ),
//                     //     const CircleAvatar(
//                     //       radius: 19,
//                     //       backgroundImage:
//                     //           NetworkImage('https://i.pravatar.cc/150?img=3'),
//                     //     ),
//                     //   ],
//                     // ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 // Sync Status Card
//                 _SyncStatusCard(unsyncedLessonsAsync: unsyncedLessonsAsync),
//                 const SizedBox(height: 24),
//                 // My statistics
//                 const Text(
//                   'My statistics',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           context.push('/lesson-history');
//                         },
//                         child: _StatCard(
//                           color: const Color(0xFFB8F7B2),
//                           icon: Icons.menu_book,
//                           label: 'History',
//                           count: historyCount,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           context.push('/downloaded-lessons');
//                         },
//                         child: downloadedLessonsAsync.when(
//                         data: (downloadedCount) => _StatCard(
//                           color: const Color(0xFF4A90E2),
//                           icon: Icons.download_done,
//                           iconColor: Colors.white,
//                           iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
//                           label: 'Downloaded',
//                           count: downloadedCount,
//                         ),
//                         loading: () => _StatCard(
//                           color: const Color(0xFF4A90E2),
//                           icon: Icons.download_done,
//                           iconColor: Colors.white,
//                           iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
//                           label: 'Downloaded',
//                           count: 0,
//                         ),
//                         error: (_, __) => _StatCard(
//                           color: const Color(0xFF4A90E2),
//                           icon: Icons.download_done,
//                           iconColor: Colors.white,
//                           iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
//                           label: 'Downloaded',
//                           count: 0,
//                         ),
//                       ),
//                     ),
//                   ),
//                   ],
//                 ),
//                 const SizedBox(height: 32),
//                 // Saved Collections/lessons
//                 const Text(
//                   'Bookmarks',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 bookmarkCountAsync.when(
//                   data: (bookmarkCount) => _SavedLessonsCard(savedLessons: bookmarkCount),
//                   loading: () => const _SavedLessonsCard(savedLessons: 0),
//                   error: (_, __) => const _SavedLessonsCard(savedLessons: 0),
//                 ),
//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SyncStatusCard extends ConsumerWidget {
//   final AsyncValue<List<dynamic>> unsyncedLessonsAsync;
//   const _SyncStatusCard({required this.unsyncedLessonsAsync});

//   Future<void> _handleSync(WidgetRef ref) async {
//     final syncState = ref.read(syncStateProvider.notifier);
    
//     try {
//       syncState.startSync();
      
//       debugPrint('[ReviewScreen] Starting sync process...');
      
//       // Get current unsynced lessons count before sync
//       final unsyncedBefore = await ref.read(unsyncedLessonsProvider.future);
//       debugPrint('[ReviewScreen] Unsynced lessons before sync: ${unsyncedBefore.length}');
      
//       // Trigger the sync provider and get results
//       final syncResults = await ref.read(syncAllProgressProvider.future);
//       debugPrint('[ReviewScreen] Sync results: $syncResults');
      
//       // Invalidate the unsynced lessons provider to refresh the data
//       ref.invalidate(unsyncedLessonsProvider);
      
//       // Add a small delay to ensure database updates are committed
//       await Future.delayed(const Duration(milliseconds: 500));
      
//       // Force refresh the provider by reading it again
//       ref.invalidate(unsyncedLessonsProvider);
      
//       // Also invalidate related providers to ensure all data is fresh
//       ref.invalidate(lessonHistoryProvider);
//       ref.invalidate(bookmarkCountProvider);
      
//       // Add another small delay to ensure all providers are refreshed
//       await Future.delayed(const Duration(milliseconds: 200));
      
//       // Get unsynced lessons count after sync
//       final unsyncedAfter = await ref.read(unsyncedLessonsProvider.future);
//       debugPrint('[ReviewScreen] Unsynced lessons after sync: ${unsyncedAfter.length}');
      
//       // Check if sync actually worked by verifying unsynced count decreased
//       final unsyncedDecreased = unsyncedAfter.length < unsyncedBefore.length;
//       final totalSynced = (syncResults['synced']['lessons'] as int) + 
//                          (syncResults['synced']['courses'] as int) + 
//                          (syncResults['synced']['modules'] as int);
      
//       debugPrint('[ReviewScreen] Sync verification:');
//       print('  Unsynced before: ${unsyncedBefore.length}');
//       print('  Unsynced after: ${unsyncedAfter.length}');
//       print('  Decreased: $unsyncedDecreased');
//       print('  Total synced (reported): $totalSynced');
      
//       if (unsyncedDecreased) {
//         final syncedCount = unsyncedBefore.length - unsyncedAfter.length;
//         syncState.setSuccess('Sync successful! $syncedCount lesson${syncedCount == 1 ? '' : 's'} synced to cloud.');
//       } else if (totalSynced > 0) {
//         // Sync reported success but unsynced count didn't decrease
//         syncState.setError('Sync completed but data may not be fully synced. Please check your connection and try again.');
//       } else {
//         syncState.setError('Sync completed but no items were synced. Check your internet connection.');
//       }
//     } catch (e) {
//       debugPrint('[ReviewScreen] Sync error: $e');
//       syncState.setError('Sync failed: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final syncState = ref.watch(syncStateProvider);
    
//     // Show success/error messages
//     if (syncState.isSuccess && syncState.message != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(syncState.message!),
//             backgroundColor: Colors.green,
//           ),
//         );
//         // Reset the state after showing the message
//         ref.read(syncStateProvider.notifier).reset();
//       });
//     } else if (syncState.isError && syncState.message != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(syncState.message!),
//             backgroundColor: Colors.red,
//           ),
//         );
//         // Reset the state after showing the message
//         ref.read(syncStateProvider.notifier).reset();
//       });
//     }

//     return unsyncedLessonsAsync.when(
//       data: (unsyncedLessons) {
//         if (unsyncedLessons.isEmpty) {
//           return Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
//             ),
//             child: const Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Icon(Icons.cloud_done, color: Colors.green, size: 32),
//                 SizedBox(height: 12),
//                 Text(
//                   'All progress is synced',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF232B3A),
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Your lesson progress is safely backed up to the cloud.',
//                   style: TextStyle(fontSize: 15, color: Colors.grey),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           );
//         } else {
//           return Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFF3E0),
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const Icon(Icons.cloud_off, color: Colors.orange, size: 32),
//                 const SizedBox(height: 12),
//                 Text(
//                   '${unsyncedLessons.length} lesson${unsyncedLessons.length == 1 ? '' : 's'} not yet synced',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF232B3A),
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Connect to the internet to sync your progress to the cloud.',
//                   style: TextStyle(fontSize: 15, color: Colors.orange),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   onPressed: syncState.isSyncing ? null : () {
//                     debugPrint('[ReviewScreen] Sync button pressed, isSyncing: ${syncState.isSyncing}');
//                     _handleSync(ref);
//                   },
//                   child: syncState.isSyncing
//                       ? const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             ),
//                             SizedBox(width: 12),
//                             Text(
//                               'Syncing...',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ],
//                         )
//                       : const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.sync, color: Colors.white, size: 20),
//                             SizedBox(width: 8),
//                             Text(
//                               'Sync Now',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),
//               ],
//             ),
//           );
//         }
//       },
//       loading: () => Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//         ),
//         child: const Center(child: CircularProgressIndicator()),
//       ),
//       error: (e, _) => Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//         ),
//         child: Column(
//           children: [
//             const Icon(Icons.error, color: Colors.red),
//             const SizedBox(height: 8),
//             Text('Error: $e'),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _StatCard extends StatelessWidget {
//   final Color color;
//   final IconData icon;
//   final String label;
//   final int count;
//   final Color? iconColor;
//   final Color? iconBackgroundColor;

//   const _StatCard({
//     required this.color,
//     required this.icon,
//     required this.label,
//     required this.count,
//     this.iconColor,
//     this.iconBackgroundColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 120,
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: iconBackgroundColor ?? Colors.black.withValues(alpha: 0.08),
//               shape: BoxShape.circle,
//             ),
//             padding: const EdgeInsets.all(10),
//             child: Icon(icon, color: iconColor ?? Colors.black54, size: 28),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             count.toString(),
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SavedLessonsCard extends StatelessWidget {
//   final int savedLessons;
//   const _SavedLessonsCard({required this.savedLessons});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         context.push('/bookmarks');
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF8F8F8),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.save_alt, color: Color(0xFFF2992F), size: 28),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Bookmarked Lessons',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   Text(
//                     '$savedLessons lessons',
//                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(
//               Icons.arrow_forward_ios,
//               color: Colors.grey,
//               size: 16,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
