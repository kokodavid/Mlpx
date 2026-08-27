import 'dart:convert';
import 'dart:io';

import 'package:milpress/features/profile/models/profile_model.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:path_provider/path_provider.dart';

const _offlineProfilesDirectoryName = 'offline_profiles_v2';
const _profileDataFileName = 'profile.json';

class ProfileOfflineStorageService {
  String _userId() {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user found');
    }
    return userId;
  }

  Future<Directory> getProfileDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      '${appDirectory.path}/$_offlineProfilesDirectoryName/${_userId()}',
    );
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final profileDirectory = await getProfileDirectory();
    if (!await profileDirectory.exists()) {
      await profileDirectory.create(recursive: true);
    }

    final profileDataFile = _profileDataFile(profileDirectory);
    await profileDataFile.writeAsString(jsonEncode(profile.toJson()));
  }

  Future<ProfileModel?> readProfile() async {
    try {
      final profileDirectory = await getProfileDirectory();
      final profileDataFile = _profileDataFile(profileDirectory);
      if (!await profileDataFile.exists()) {
        return null;
      }

      final data = jsonDecode(await profileDataFile.readAsString());
      if (data is! Map<String, dynamic>) {
        return null;
      }

      return ProfileModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  File _profileDataFile(Directory profileDirectory) {
    return File('${profileDirectory.path}/$_profileDataFileName');
  }
}
