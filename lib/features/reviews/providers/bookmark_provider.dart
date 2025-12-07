import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/reviews/services/bookmark_service.dart';
import 'package:milpress/features/reviews/models/bookmark_model.dart';
import 'package:milpress/utils/supabase_config.dart';

final bookmarkServiceProvider = Provider((ref) => BookmarkService());

final userBookmarksProvider = FutureProvider<List<BookmarkModel>>((ref) async {
  final user = SupabaseConfig.currentUser;
  final userId = user?.id;
  if (userId == null) return [];
  
  final service = ref.watch(bookmarkServiceProvider);
  return service.getUserBookmarks(userId);
});

final unsyncedBookmarksProvider = FutureProvider<List<BookmarkModel>>((ref) async {
  final user = SupabaseConfig.currentUser;
  final userId = user?.id;
  if (userId == null) return [];
  
  final service = ref.watch(bookmarkServiceProvider);
  return service.getUnsyncedBookmarks(userId);
});

final bookmarkCountProvider = FutureProvider<int>((ref) async {
  final bookmarks = await ref.watch(userBookmarksProvider.future);
  return bookmarks.length;
});

// Provider to check if a specific lesson is bookmarked
final isLessonBookmarkedProvider = FutureProvider.family<bool, String>((ref, lessonId) async {
  final user = SupabaseConfig.currentUser;
  final userId = user?.id;
  if (userId == null) return false;
  
  final service = ref.watch(bookmarkServiceProvider);
  return service.isBookmarked(lessonId: lessonId, userId: userId);
});

// Provider to add a bookmark
final addBookmarkProvider = FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final user = SupabaseConfig.currentUser;
  final userId = user?.id;
  if (userId == null) throw Exception('User not logged in');
  
  final service = ref.watch(bookmarkServiceProvider);
  await service.addBookmark(
    lessonId: params['lessonId']!,
    courseId: params['courseId']!,
    moduleId: params['moduleId']!,
    lessonTitle: params['lessonTitle']!,
    courseTitle: params['courseTitle']!,
    moduleTitle: params['moduleTitle']!,
    userId: userId,
  );
  
  // Invalidate related providers to refresh UI
  ref.invalidate(userBookmarksProvider);
  ref.invalidate(bookmarkCountProvider);
  ref.invalidate(isLessonBookmarkedProvider(params['lessonId']!));
});

// Provider to remove a bookmark
final removeBookmarkProvider = FutureProvider.family<void, String>((ref, lessonId) async {
  final user = SupabaseConfig.currentUser;
  final userId = user?.id;
  if (userId == null) throw Exception('User not logged in');
  
  final service = ref.watch(bookmarkServiceProvider);
  await service.removeBookmark(lessonId: lessonId, userId: userId);
  
  // Invalidate related providers to refresh UI
  ref.invalidate(userBookmarksProvider);
  ref.invalidate(bookmarkCountProvider);
  ref.invalidate(isLessonBookmarkedProvider(lessonId));
});

// Provider to sync bookmarks
final syncBookmarksProvider = FutureProvider<void>((ref) async {
  final user = SupabaseConfig.currentUser;
  final userId = user?.id;
  if (userId == null) throw Exception('User not logged in');
  
  final service = ref.watch(bookmarkServiceProvider);
  await service.syncBookmarks(userId);
  
  // Invalidate related providers to refresh UI
  ref.invalidate(userBookmarksProvider);
  ref.invalidate(unsyncedBookmarksProvider);
  ref.invalidate(bookmarkCountProvider);
});

// Provider to fetch bookmarks from cloud
final fetchBookmarksFromCloudProvider = FutureProvider<void>((ref) async {
  final user = SupabaseConfig.currentUser;
  final userId = user?.id;
  if (userId == null) throw Exception('User not logged in');
  
  final service = ref.watch(bookmarkServiceProvider);
  await service.fetchBookmarksFromCloud(userId);
  
  // Invalidate related providers to refresh UI
  ref.invalidate(userBookmarksProvider);
  ref.invalidate(unsyncedBookmarksProvider);
  ref.invalidate(bookmarkCountProvider);
}); 