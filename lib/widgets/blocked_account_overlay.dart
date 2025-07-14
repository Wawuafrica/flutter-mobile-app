import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/services/auth_service.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class BlockedAccountOverlay extends StatelessWidget {
  const BlockedAccountOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Account Temporarily Disabled',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your account has been temporarily disabled. Please contact support for more information.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    authService.logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wawuColors.buttonPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Logout', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
