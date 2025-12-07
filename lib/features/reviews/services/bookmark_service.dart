import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:milpress/features/reviews/models/bookmark_model.dart';
import 'package:milpress/utils/supabase_config.dart';

class BookmarkService {
  static const String _boxName = 'bookmarks';

  Future<Box<BookmarkModel>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<BookmarkModel>(_boxName);
    }
    return Hive.box<BookmarkModel>(_boxName);
  }

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
    final box = await _getBox();
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
      needsSync: true,
    );

    await box.put(uuid, bookmark);
  }

  // Remove a bookmark
  Future<void> removeBookmark({
    required String lessonId,
    required String userId,
  }) async {
    final box = await _getBox();
    final bookmarks = box.values.where((b) => 
      b.lessonId == lessonId && b.userId == userId
    ).toList();

    for (final bookmark in bookmarks) {
      await box.delete(bookmark.id);
    }
  }

  // Check if a lesson is bookmarked
  Future<bool> isBookmarked({
    required String lessonId,
    required String userId,
  }) async {
    final box = await _getBox();
    return box.values.any((b) => 
      b.lessonId == lessonId && b.userId == userId
    );
  }

  // Get all bookmarks for a user
  Future<List<BookmarkModel>> getUserBookmarks(String userId) async {
    final box = await _getBox();
    return box.values
        .where((b) => b.userId == userId)
        .toList()
      ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt)); // Most recent first
  }

  // Get bookmarks that need sync
  Future<List<BookmarkModel>> getUnsyncedBookmarks(String userId) async {
    final box = await _getBox();
    return box.values
        .where((b) => b.userId == userId && b.needsSync)
        .toList();
  }

  // Sync bookmarks with Supabase
  Future<void> syncBookmarks(String userId) async {
    final box = await _getBox();
    final unsyncedBookmarks = await getUnsyncedBookmarks(userId);
    
    if (unsyncedBookmarks.isEmpty) return;

    final supabase = SupabaseConfig.client;

    for (final bookmark in unsyncedBookmarks) {
      try {
        // Check if bookmark already exists in Supabase
        final existing = await supabase
            .from('bookmarks')
            .select()
            .eq('user_id', userId)
            .eq('lesson_id', bookmark.lessonId)
            .single();

        if (existing.isNotEmpty) {
          // Update existing bookmark
          await supabase
              .from('bookmarks')
              .update(bookmark.toJson())
              .eq('id', existing['id']);
        } else {
          // Insert new bookmark
          await supabase
              .from('bookmarks')
              .insert(bookmark.toJson());
        }

        // Mark as synced
        final syncedBookmark = bookmark.copyWith(needsSync: false);
        await box.put(bookmark.id, syncedBookmark);

      } catch (e) {
        print('Error syncing bookmark ${bookmark.id}: $e');
        // Keep needsSync as true for retry
      }
    }
  }

  // Fetch bookmarks from Supabase and update local cache
  Future<void> fetchBookmarksFromCloud(String userId) async {
    final box = await _getBox();
    final supabase = SupabaseConfig.client;

    try {
      final response = await supabase
          .from('bookmarks')
          .select()
          .eq('user_id', userId);

      for (final bookmarkData in response) {
        final bookmark = BookmarkModel.fromJson(bookmarkData);
        // Mark as synced since it came from cloud
        final syncedBookmark = bookmark.copyWith(needsSync: false);
        await box.put(bookmark.id, syncedBookmark);
      }
    } catch (e) {
      print('Error fetching bookmarks from cloud: $e');
    }
  }

  // Clear all bookmarks (for testing or user logout)
  Future<void> clearAllBookmarks() async {
    final box = await _getBox();
    await box.clear();
  }
} 