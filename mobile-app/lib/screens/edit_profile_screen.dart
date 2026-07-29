import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:footfalls_app/providers/auth_controller.dart';
import 'package:footfalls_app/providers/profile_controller.dart';
import 'package:footfalls_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _storeNameController;
  late TextEditingController _storeAddressController;
  late TextEditingController _bioController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final profile = ref.read(profileControllerProvider);
    
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _storeNameController = TextEditingController(text: profile.storeName != 'Unknown Store' ? profile.storeName : '');
    _storeAddressController = TextEditingController(text: profile.storeAddress != 'No address' ? profile.storeAddress : '');
    _bioController = TextEditingController(text: profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // compress large images
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Open Camera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded, color: AppTheme.errorRed),
                title: const Text('Cancel', style: TextStyle(color: AppTheme.errorRed)),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await ref.read(profileControllerProvider.notifier).saveProfile(
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          storeName: _storeNameController.text.trim(),
          storeAddress: _storeAddressController.text.trim(),
          bio: _bioController.text.trim(),
          newProfileImage: _selectedImage,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppTheme.successGreen),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  ImageProvider? _getProfileImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }
    final file = File(photoUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileControllerProvider).isLoading;
    final user = ref.watch(authProvider).user;
    final colorScheme = Theme.of(context).colorScheme;

    final existingImageProvider = _getProfileImageProvider(user?.photoUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _showImagePickerBottomSheet,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                              backgroundImage: _selectedImage != null 
                                ? FileImage(_selectedImage!) as ImageProvider
                                : existingImageProvider,
                              child: (_selectedImage == null && existingImageProvider == null)
                                  ? Icon(Icons.person, size: 50, color: colorScheme.primary)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      initialValue: user?.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter your phone number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Store Name',
                        prefixIcon: Icon(Icons.store_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter the store name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Store Address',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter the store address' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
