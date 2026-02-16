/*import '../models/profile_model.dart';

class EditProfileModel {
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const EditProfileModel({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.avatarUrl,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  /// Create an EditProfileModel pre-filled from an existing ProfileModel
  factory EditProfileModel.fromProfile(ProfileModel profile) {
    return EditProfileModel(
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
    );
  }

  /// Returns true if all required fields are valid for submission
  bool get isValid =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  EditProfileModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return EditProfileModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}*/