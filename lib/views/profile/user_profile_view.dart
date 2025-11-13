import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../routes/app_pages.dart';
import '../../services/auth_service.dart';
import '../../services/toast_service.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadUserData(authService),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?['userData'] as Map<String, dynamic>?;
          final userEmail = userData?['email']?.toString() ?? 
                           snapshot.data?['email']?.toString() ?? 
                           'Unknown';
          final userName = userData?['name']?.toString() ?? 'Unknown';
          final userType = snapshot.data?['userType'] as UserType?;
          final userTypeLabel = userType == UserType.assessmentOfficer
              ? 'Assessment Officer'
              : userType == UserType.cashier
              ? 'Cashier'
              : 'Unknown';
          final gender = userData?['gender']?.toString();
          final streetName = userData?['street_name']?.toString();
          final streetNumber = userData?['street_number']?.toString();
          final ward = userData?['ward']?.toString();
          final constituency = userData?['constituency']?.toString();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Details Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Information Section
                      _buildSectionTitle('Account Information'),
                      const SizedBox(height: 16),
                      if (userName != 'Unknown')
                        _buildInfoCard(
                          icon: Icons.person_outline,
                          title: 'Name',
                          value: userName,
                          iconColor: Colors.purple,
                        ),
                      if (userName != 'Unknown') const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: userEmail,
                        iconColor: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.badge_outlined,
                        title: 'Role',
                        value: userTypeLabel,
                        iconColor: Colors.green,
                      ),
                      if (gender != null && gender.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.person,
                          title: 'Gender',
                          value: gender == 'M' ? 'Male' : gender == 'F' ? 'Female' : gender,
                          iconColor: Colors.orange,
                        ),
                      ],
                      if ((streetName != null && streetName.isNotEmpty) || 
                          (streetNumber != null && streetNumber.isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.location_on_outlined,
                          title: 'Address',
                          value: [
                            if (streetNumber != null && streetNumber.isNotEmpty) streetNumber,
                            if (streetName != null && streetName.isNotEmpty) streetName,
                          ].join(' '),
                          iconColor: Colors.red,
                        ),
                      ],
                      if (ward != null && ward.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.map_outlined,
                          title: 'Ward',
                          value: ward,
                          iconColor: Colors.teal,
                        ),
                      ],
                      if (constituency != null && constituency.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.account_balance_outlined,
                          title: 'Constituency',
                          value: constituency,
                          iconColor: Colors.indigo,
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Actions Section
                      _buildSectionTitle('Actions'),
                      const SizedBox(height: 16),
                      _buildActionCard(
                        icon: Icons.edit_outlined,
                        title: 'Update Profile',
                        subtitle: 'Update your profile information',
                        iconColor: Colors.blue,
                        onTap: () => _showUpdateProfileDialog(
                          context,
                          authService,
                          userName,
                          userEmail,
                          gender ?? 'M',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        iconColor: Colors.orange,
                        onTap: () => _showChangePasswordDialog(context, authService),
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out from your account',
                        iconColor: Colors.red,
                        onTap: () async {
                          final confirm = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await authService.logout();
                            Get.offAllNamed(Routes.onboarding);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadUserData(AuthService authService) async {
    // Fallback to saved data
    final email = await authService.getSavedUserEmail();
    final userType = await authService.getSavedUserType();
    
    // Call the API to get user data
    try {
      final apiResponse = await authService.getUserData();
      
      // Log the response
      if (kDebugMode) {
        Get.log('User Data API Response: ${jsonEncode(apiResponse)}');
        print('\n=== User Data API Response ===');
        print(jsonEncode(apiResponse));
        print('==============================\n');
      }
      
      // Extract userData from response if available
      if (apiResponse['userData'] != null) {
        return {
          'userData': apiResponse['userData'],
          'email': apiResponse['userData']?['email'] ?? email ?? 'Unknown',
          'userType': userType,
        };
      }
    } catch (e) {
      // Log error if API call fails
      if (kDebugMode) {
        Get.log('Error fetching user data: $e');
        print('\n=== Error fetching user data ===');
        print('Error: $e');
        print('================================\n');
      }
    }
    
    // Return fallback data if API call failed or no userData in response
    return {'email': email ?? 'Unknown', 'userType': userType};
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateProfileDialog(
    BuildContext context,
    AuthService authService,
    String currentName,
    String currentEmail,
    String currentGender,
  ) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    String selectedGender = currentGender.toUpperCase();

    Get.dialog(
      AlertDialog(
        title: const Text('Update Profile'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Male')),
                      DropdownMenuItem(value: 'F', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedGender = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();

              if (name.isEmpty) {
                ToastService.showError('Please enter your name');
                return;
              }

              if (email.isEmpty) {
                ToastService.showError('Please enter your email');
                return;
              }

              if (!GetUtils.isEmail(email)) {
                ToastService.showError('Please enter a valid email');
                return;
              }

              try {
                Get.back(); // Close dialog
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );

                final response = await authService.updateProfile(
                  name: name,
                  email: email,
                  gender: selectedGender,
                );

                if (response['success'] == true) {
                  Get.back(); // Close loading dialog
                  ToastService.showSuccess(
                    response['message']?.toString() ?? 'Profile updated successfully',
                  );
                  // Refresh the page by navigating away and back
                  Get.offNamed(Routes.userProfile);
                } else {
                  Get.back(); // Close loading dialog
                  ToastService.showError(
                    response['message']?.toString() ?? 'Failed to update profile',
                  );
                }
              } catch (e) {
                if (Get.isDialogOpen ?? false) {
                  Get.back(); // Close loading dialog if still open
                }
                ToastService.showError(e.toString().replaceFirst('AuthException: ', ''));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthService authService,
  ) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureOldPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureOldPassword = !obscureOldPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: obscureOldPassword,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: obscureNewPassword,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: obscureConfirmPassword,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (oldPassword.isEmpty) {
                ToastService.showError('Please enter your old password');
                return;
              }

              if (newPassword.isEmpty) {
                ToastService.showError('Please enter a new password');
                return;
              }

              if (newPassword.length < 6) {
                ToastService.showError('Password must be at least 6 characters');
                return;
              }

              if (newPassword != confirmPassword) {
                ToastService.showError('New passwords do not match');
                return;
              }

              if (oldPassword == newPassword) {
                ToastService.showError('New password must be different from old password');
                return;
              }

              try {
                Get.back(); // Close dialog
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );

                final response = await authService.changePassword(
                  oldPassword: oldPassword,
                  newPassword: newPassword,
                );

                if (response['success'] == true) {
                  Get.back(); // Close loading dialog
                  ToastService.showSuccess(
                    response['message']?.toString() ?? 'Password changed successfully',
                  );
                } else {
                  Get.back(); // Close loading dialog
                  ToastService.showError(
                    response['message']?.toString() ?? 'Failed to change password',
                  );
                }
              } catch (e) {
                if (Get.isDialogOpen ?? false) {
                  Get.back(); // Close loading dialog if still open
                }
                ToastService.showError(e.toString().replaceFirst('AuthException: ', ''));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}
