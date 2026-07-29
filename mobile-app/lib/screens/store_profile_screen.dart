import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:footfalls_app/core/theme/app_theme.dart';
import 'package:footfalls_app/core/config/api_constants.dart';

final storeProfileProvider = StateNotifierProvider.autoDispose<StoreProfileController, Map<String, dynamic>?>((ref) {
  return StoreProfileController(ref.watch(dioProvider));
});

class StoreProfileController extends StateNotifier<Map<String, dynamic>?> {
  final Dio _dio;
  bool isSaving = false;

  StoreProfileController(this._dio) : super(null) {
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _dio.get(ApiConstants.storeProfile);
      state = res.data;
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    isSaving = true;
    state = {...?state}; // trigger rebuild if needed, though we track isSaving separately usually
    try {
      final res = await _dio.put(ApiConstants.storeProfile, data: updateData);
      state = res.data;
      return true;
    } catch (e) {
      return false;
    } finally {
      isSaving = false;
    }
  }
}

class StoreProfileScreen extends ConsumerStatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  ConsumerState<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends ConsumerState<StoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ownerController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ownerController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _populate(Map<String, dynamic> data) {
    if (_nameController.text.isEmpty) {
      _nameController.text = data['store_name'] ?? '';
      _ownerController.text = data['owner_name'] ?? '';
      _phoneController.text = data['phone_number'] ?? '';
      _emailController.text = data['email'] ?? '';
      _addressController.text = data['address'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final success = await ref.read(storeProfileProvider.notifier).updateProfile({
        'store_name': _nameController.text,
        'owner_name': _ownerController.text,
        'phone_number': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
      });
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile updated successfully'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(storeProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _populate(profile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 4),
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.storefront_rounded, size: 56, color: colorScheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text('Edit Store Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Update your store configuration for analytics.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 40),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Store Name', prefixIcon: Icon(Icons.business_rounded)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(labelText: 'Owner Name', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Physical Address', prefixIcon: Icon(Icons.location_on_outlined), alignLabelWithHint: true),
                maxLines: 3,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSaving 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
