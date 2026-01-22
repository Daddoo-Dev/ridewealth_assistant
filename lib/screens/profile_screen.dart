import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../delete_account_button.dart';
import '../theme/app_themes.dart';

class ProfileScreen extends StatefulWidget {
  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();

        var data = response;
        setState(() {
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';

          // Parse address
          String fullAddress = data['address'] ?? '';
          List<String> addressParts = fullAddress.split(',');
          if (addressParts.length >= 3) {
            _addressController.text = addressParts[0].trim();
            _cityController.text = addressParts[1].trim();
            List<String> stateZip = addressParts[2].trim().split(' ');
            if (stateZip.length >= 2) {
              _stateController.text = stateZip[0];
              _zipController.text = stateZip[1];
            }
          } else {
            _addressController.text = fullAddress;
          }
        });
      } catch (e) {
        print("Error loading user profile: $e");
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      User? user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Combine address parts
        String fullAddress =
            '${_addressController.text}, ${_cityController.text}, ${_stateController.text} ${_zipController.text}';

        try {
          await Supabase.instance.client
              .from('users')
              .upsert({
            'id': user.id,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'address': fullAddress,
            'city': _cityController.text,
            'state': _stateController.text,
            'zip': _zipController.text,
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );
        } catch (e) {
          print("Error updating profile: $e");
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppThemes.buildAppBar(context, 'User Profile'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your phone number' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your address' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'City'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your city' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(labelText: 'State'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your state' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: InputDecoration(labelText: 'ZIP Code'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your ZIP code' : null,
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Note: Phone number and address information are collected solely for account identification purposes to ensure account uniqueness and prevent duplicate accounts. Personal data is not and will not be collected, shared, or sold for any purpose.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  child: Text('Update Profile'),
                ),
              ),
              SizedBox(height: 12),
              DeleteAccountButton(),
            ],
          ),
        ),
      ),
    );
  }
}