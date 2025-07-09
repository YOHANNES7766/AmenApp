import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../shared/services/auth_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../widgets/profile_header.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _error;

  // Text controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _campusController;
  late TextEditingController _departmentController;

  // Dropdown options - matching registration form exactly
  final List<String> _campusOptions = [
    'MAIN CAMPUS',
    'HIT CAMPUS',
    'STATIONERY CAMPUS'
  ];

  final List<String> _departmentOptions = [
    'SWE',
    'CS',
    'IS',
    'SPORT',
    'ELECTRICAL',
    'CIVIL',
    'LAW'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _campusController = TextEditingController();
    _departmentController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _campusController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    if (_userProfile != null) {
      _nameController.text = _userProfile!['name']?.toString() ?? '';
      _phoneController.text = _userProfile!['phone']?.toString() ?? '';
      _campusController.text = _userProfile!['campus']?.toString() ?? '';
      _departmentController.text =
          _userProfile!['department']?.toString() ?? '';
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profile = await authService.fetchUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isLoading = false;
        _error = null;
      });
      _initializeControllers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        campus: _campusController.text.trim(),
        department: _departmentController.text.trim(),
      );

      // Reload profile to get updated data
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditDialog(
      String field, TextEditingController controller, String title,
      {bool isDropdown = false, List<String>? options}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: isDropdown && options != null
            ? _buildDropdownField(controller, options)
            : _buildTextField(controller, title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      autofocus: true,
    );
  }

  Widget _buildDropdownField(
      TextEditingController controller, List<String> options) {
    String currentValue = controller.text;
    if (!options.contains(currentValue)) {
      currentValue = options.first;
    }

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Select option',
      ),
      items: options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          controller.text = newValue;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_userProfile == null) {
      return const Center(child: Text('No profile data available'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          ProfileHeader(
            userProfile: _userProfile,
            onChangePicture: _handleImageSelection,
          ),

          // Personal Information Section
          _buildSection(
            title: 'Personal Information',
            children: [
              _buildClickableInfoTile(
                'Name',
                _userProfile!['name']?.toString() ?? 'Not provided',
                Icons.person_outline,
                () => _showEditDialog('name', _nameController, 'Name'),
              ),
              _buildInfoTile(
                'Email',
                _userProfile!['email']?.toString() ?? 'Not provided',
                Icons.email_outlined,
              ),
              _buildClickableInfoTile(
                'Phone',
                _userProfile!['phone']?.toString() ?? 'Not provided',
                Icons.phone_outlined,
                () => _showEditDialog('phone', _phoneController, 'Phone'),
              ),
              _buildClickableInfoTile(
                'Campus',
                _userProfile!['campus']?.toString() ?? 'Not provided',
                Icons.school_outlined,
                () => _showEditDialog('campus', _campusController, 'Campus',
                    isDropdown: true, options: _campusOptions),
              ),
              _buildClickableInfoTile(
                'Department',
                _userProfile!['department']?.toString() ?? 'Not provided',
                Icons.business_outlined,
                () => _showEditDialog(
                    'department', _departmentController, 'Department',
                    isDropdown: true, options: _departmentOptions),
              ),
              // Role is always read-only
              _buildInfoTile(
                'Role',
                _userProfile!['role']?.toString() ?? 'user',
                Icons.admin_panel_settings_outlined,
              ),
            ],
          ),

          // Save Button at the bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildClickableInfoTile(
      String label, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
        ),
      ),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _handleImageSelection() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(AppLocalizations.of(context).takePhoto),
            onTap: () async {
              Navigator.pop(context);
              await _pickAndUploadImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(AppLocalizations.of(context).chooseFromGallery),
            onTap: () async {
              Navigator.pop(context);
              await _pickAndUploadImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final authService = Provider.of<AuthService>(context, listen: false);

          // Upload the image (this also updates the user profile automatically)
          await authService.uploadProfilePicture(File(image.path));

          // Reload the profile to get updated data
          await _loadUserProfile();

          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
