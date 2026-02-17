import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import '../../../utils/app_colors.dart';
import '../providers/edit_profile_provider.dart';
import '../widgets/profile_avatar_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  bool _controllersInitialised = false;
  bool _hasEdited = false;
  String _originalFirstName = '';
  String _originalLastName = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Lazily initialise controllers once the provider has real data
  void _initControllers(String firstName, String lastName) {
    if (_controllersInitialised) return;
    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _originalFirstName = firstName;
    _originalLastName = lastName;
    _controllersInitialised = true;
  }

  void _checkIfEdited() {
    final currentFirstName = _firstNameController.text.trim();
    final currentLastName = _lastNameController.text.trim();
    setState(() {
      _hasEdited = currentFirstName != _originalFirstName ||
          currentLastName != _originalLastName;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      ref.read(editProfileProvider.notifier).uploadAvatar(picked.path);
    }
  }

  String _buildInitials(String firstName, String lastName) {
    final f = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final l = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return '$f$l';
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editProfileProvider);
    final profile = editState.profile;

    // Initialise controllers as soon as we have data
    if (profile != null) {
      _initControllers(profile.firstName, profile.lastName);
    }

    // Listen for success to pop back
    ref.listen(editProfileProvider, (previous, next) {
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Avatar picker
            if (profile != null)
              Center(
                child: ProfileAvatarPicker(
                  avatarUrl: profile.avatarUrl,
                  initials: _buildInitials(
                    profile.firstName,
                    profile.lastName,
                  ),
                  isLoading: editState.isLoading,
                  onTap: _pickImage,
                ),
              ),
            const SizedBox(height: 32),

            // First Name
            _buildLabel('First Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _firstNameController,
              hint: 'Enter first name',
              onChanged: (v) {
                ref.read(editProfileProvider.notifier).setFirstName(v);
                _checkIfEdited();
              },
            ),
            const SizedBox(height: 20),

            // Last Name
            _buildLabel('Last Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _lastNameController,
              hint: 'Enter last name',
              onChanged: (v) {
                ref.read(editProfileProvider.notifier).setLastName(v);
                _checkIfEdited();
              },
            ),
            const SizedBox(height: 20),

            // Email (read-only)
            _buildLabel('Email Address'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: TextEditingController(text: profile?.email ?? ''),
              hint: 'example@abc.xyz',
              readOnly: true,
            ),
            const SizedBox(height: 6),
            const Text(
              'You cannot update email address',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFF9500),
              ),
            ),
            const SizedBox(height: 20),

            // Password (masked, read-only)
            _buildLabel('Password'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: TextEditingController(text: '••••••••••'),
              hint: '',
              readOnly: true,
              obscureText: true,
              suffixIcon: const Icon(
                Icons.visibility_outlined,
                color: Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),

            // Change Password link
            GestureDetector(
              onTap: () => context.push('/change-password'),
              child: const Text(
                'Change Password?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.errorShadowColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Error message
            if (editState.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  editState.errorMessage!,
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Update Profile button - FIXED COLOR
            CustomButton(
              text: 'Update Profile',
              onPressed: (editState.isLoading || !_hasEdited) ? null : () =>
                  ref.read(editProfileProvider.notifier).submitProfile(),
              isFilled: true,
              fillColor: !_hasEdited ? AppColors.textColor : AppColors.primaryColor,
              isLoading: editState.isLoading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffixIcon,
      ),
    );
  }
}