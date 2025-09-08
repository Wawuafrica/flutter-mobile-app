import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/wawu_africa_nest.dart' as model;
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
import 'package:wawu_mobile/screens/+HER_screens/wawu_africa_single_institution/wawu_africa_single_institution.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/utils/error_utils.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

class WawuAfricaInstitution extends StatefulWidget {
  const WawuAfricaInstitution({super.key});

  @override
  State<WawuAfricaInstitution> createState() => _WawuAfricaInstitutionState();
}

class _WawuAfricaInstitutionState extends State<WawuAfricaInstitution> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WawuAfricaProvider>(context, listen: false);
      final selectedSubCategoryId = provider.selectedSubCategory?.id;

      if (selectedSubCategoryId != null) {
        provider.clearInstitutions();
        provider
            .fetchInstitutionsBySubCategory(selectedSubCategoryId.toString());
      } else {
        print("Error: No sub-category selected to fetch institutions for.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<WawuAfricaProvider>(
          builder: (context, provider, child) {
            return Text(
              provider.selectedSubCategory?.name ?? 'Institutions',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Consumer<WawuAfricaProvider>(
        builder: (context, provider, child) {
          // --- Loading State ---
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Error State ---
          if (provider.hasError && provider.institutions.isEmpty) {
            return FullErrorDisplay(
              errorMessage:
                  provider.errorMessage ?? 'Failed to load institutions.',
              onRetry: () {
                final selectedSubCategoryId = provider.selectedSubCategory?.id;
                if (selectedSubCategoryId != null) {
                  provider.fetchInstitutionsBySubCategory(
                      selectedSubCategoryId.toString());
                }
              },
              onContactSupport: () {
                showErrorSupportDialog(
                  context: context,
                  message:
                      'If the problem persists, please contact our support team.',
                  title: 'Error',
                );
              },
            );
          }

          // --- Empty State ---
          if (provider.institutions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No Institutions Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'There are no institutions available in this section yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // --- Success State ---
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            itemCount: provider.institutions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final institution = provider.institutions[index];
              return _buildItem(context, institution);
            },
          );
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, model.WawuAfricaInstitution institution) {
    final provider = Provider.of<WawuAfricaProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        provider.selectInstitution(institution);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const WawuAfricaSingleInstitution()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
           boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: institution.profileImageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  width: 70,
                  height: 70,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  width: 70,
                  height: 70,
                  child: Icon(
                    Icons.business,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    institution.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    institution.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
