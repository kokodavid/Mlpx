import 'package:uuid/uuid.dart';
import 'package:milpress/features/reviews/models/bookmark_model.dart';
import 'package:milpress/utils/supabase_config.dart';

class BookmarkService {
  // Add a bookmark
  Future<void> addBookmark({
    required String lessonId,
    required String courseId,
    required String moduleId,
    required String lessonTitle,
    required String courseTitle,
    required String moduleTitle,
    required String userId,
  }) async {
    final now = DateTime.now();
    final uuid = Uuid().v4();

    final bookmark = BookmarkModel(
      id: uuid,
      userId: userId,
      lessonId: lessonId,
      courseId: courseId,
      moduleId: moduleId,
      lessonTitle: lessonTitle,
      courseTitle: courseTitle,
      moduleTitle: moduleTitle,
      bookmarkedAt: now,
      createdAt: now,
      updatedAt: now,
      needsSync: false,
    );

    final supabase = SupabaseConfig.client;
    await supabase.from('bookmarks').upsert(
          bookmark.toJson(),
          onConflict: 'user_id,lesson_id',
        );
  }

  // Remove a bookmark
  Future<void> removeBookmark({
    required String lessonId,
    required String userId,
  }) async {
    final supabase = SupabaseConfig.client;
    await supabase
        .from('bookmarks')
        .delete()
        .eq('user_id', userId)
        .eq('lesson_id', lessonId);
  }

  // Check if a lesson is bookmarked
  Future<bool> isBookmarked({
    required String lessonId,
    required String userId,
  }) async {
    final supabase = SupabaseConfig.client;
    final response = await supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .limit(1);
    return response is List && response.isNotEmpty;
  }

  // Get all bookmarks for a user
  Future<List<BookmarkModel>> getUserBookmarks(String userId) async {
    final supabase = SupabaseConfig.client;
    final response = await supabase
        .from('bookmarks')
        .select()
        .eq('user_id', userId)
        .order('bookmarked_at', ascending: false);

    if (response is! List) {
      return [];
    }

    return response
        .map((row) => BookmarkModel.fromJson(row))
        .toList();
  }

  // Get bookmarks that need sync
  Future<List<BookmarkModel>> getUnsyncedBookmarks(String userId) async {
    return [];
  }

  // Sync bookmarks with Supabase
  Future<void> syncBookmarks(String userId) async {
    return;
  }

  // Fetch bookmarks from Supabase and update local cache
  Future<void> fetchBookmarksFromCloud(String userId) async {
    return;
  }

  // Clear all bookmarks (for testing or user logout)
  Future<void> clearAllBookmarks() async {
    return;
  }
} 
