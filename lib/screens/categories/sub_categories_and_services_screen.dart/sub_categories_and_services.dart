import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/models/category.dart';
import 'package:wawu_mobile/screens/categories/filtered_gigs/filtered_gigs.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class ServiceDetailed extends StatefulWidget {
  const ServiceDetailed({super.key});

  @override
  State<ServiceDetailed> createState() => _ServiceDetailedState();
}

class _ServiceDetailedState extends State<ServiceDetailed> {
  Map<String, List<Service>> _subCategoryServices = {};
  Map<String, bool> _loadingServices = {};
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubCategories();
    });
  }

  Future<void> _loadSubCategories() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final selectedCategory = categoryProvider.selectedCategory;
    
    if (selectedCategory != null) {
      await categoryProvider.fetchSubCategories(selectedCategory.uuid);
    }
  }

  Future<void> _loadServicesForSubCategory(String subCategoryId) async {
    if (_subCategoryServices.containsKey(subCategoryId)) {
      return; // Already loaded
    }

    setState(() {
      _loadingServices[subCategoryId] = true;
    });

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final services = await categoryProvider.fetchServices(subCategoryId);
    
    setState(() {
      _subCategoryServices[subCategoryId] = services;
      _loadingServices[subCategoryId] = false;
    });
  }

  void _onServiceTap(Service service) {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    categoryProvider.selectService(service);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredGigs(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final selectedCategory = categoryProvider.selectedCategory;
        final categoryName = selectedCategory?.name ?? 'Category';

        return Scaffold(
          appBar: AppBar(title: Text(categoryName)),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  height: 100,
                  decoration: BoxDecoration(
                    color: wawuColors.purpleDarkContainer,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Show loading indicator only for initial subcategories load
                if (categoryProvider.isLoading && categoryProvider.subCategories.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                // Show error state for subcategories
                if (categoryProvider.hasError && categoryProvider.subCategories.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'Error: ${categoryProvider.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadSubCategories,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Show subcategories (even if some are still loading)
                ...categoryProvider.subCategories.map(
                  (subCategory) => Column(
                    children: [
                      _buildSubCategoryExpansionTile(subCategory),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                // Show empty state only if not loading and no subcategories
                if (!categoryProvider.isLoading && 
                    categoryProvider.subCategories.isEmpty && 
                    !categoryProvider.hasError)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No subcategories available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubCategoryExpansionTile(SubCategory subCategory) {
    final isLoading = _loadingServices[subCategory.uuid] ?? false;
    final services = _subCategoryServices[subCategory.uuid] ?? [];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 0.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(subCategory.name),
          onExpansionChanged: (isExpanded) {
            if (isExpanded && !_subCategoryServices.containsKey(subCategory.uuid)) {
              _loadServicesForSubCategory(subCategory.uuid);
            }
          },
          childrenPadding: const EdgeInsets.only(
            left: 0,
            right: 0,
            bottom: 16,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildServicesContent(subCategory.uuid, isLoading, services),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesContent(String subCategoryId, bool isLoading, List<Service> services) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading services...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No services available',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: services.map((service) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: GestureDetector(
            onTap: () => _onServiceTap(service),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                // color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                service.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ).toList(),
    );
  }
}