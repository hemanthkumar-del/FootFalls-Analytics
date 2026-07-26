import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

final storeProfileProvider = StateNotifierProvider.autoDispose<StoreProfileController, Map<String, dynamic>?>((ref) {
  return StoreProfileController(ref.watch(dioProvider));
});

class StoreProfileController extends StateNotifier<Map<String, dynamic>?> {
  final Dio _dio;

  StoreProfileController(this._dio) : super(null) {
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _dio.get('/store/profile');
      state = res.data;
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final res = await _dio.put('/store/profile', data: updateData);
      state = res.data;
      return true;
    } catch (e) {
      return false;
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(storeProfileProvider);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final success = await ref.read(storeProfileProvider.notifier).updateProfile({
                  'store_name': _nameController.text,
                  'owner_name': _ownerController.text,
                  'phone_number': _phoneController.text,
                  'email': _emailController.text,
                  'address': _addressController.text,
                });
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                }
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.store, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Store Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Physical Address', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
