import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/models/variant.dart';

class SinglePackage extends StatefulWidget {
  const SinglePackage({super.key});

  @override
  State<SinglePackage> createState() => _SinglePackageState();
}

class _SinglePackageState extends State<SinglePackage> {
  String? _selectedVariantValue;
  List<Product> _similarProducts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSimilarProducts();
    });
  }

  void _loadSimilarProducts() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final selectedProduct = productProvider.selectedProduct;

    if (selectedProduct != null) {
      _similarProducts =
          productProvider.products
              .where(
                (product) =>
                    product.id != selectedProduct.id &&
                    (product.category == selectedProduct.category ||
                        product.tags.any(
                          (tag) => selectedProduct.tags.contains(tag),
                        )),
              )
              .take(4)
              .toList();

      if (mounted) setState(() {});
    }
  }

  Future<void> _openWhatsApp(Product product) async {
    const String phoneNumber = "2347050622222";
    String message = _buildWhatsAppMessage(product);
    String encodedMessage = Uri.encodeComponent(message);

    final String whatsappUrl =
        "https://wa.me/$phoneNumber?text=$encodedMessage";
    final Uri url = Uri.parse(whatsappUrl);

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String _buildWhatsAppMessage(Product product) {
    StringBuffer message = StringBuffer();

    message.writeln("🛍️ *PRODUCT INQUIRY*");
    message.writeln("━━━━━━━━━━━━━━━━━━━━");
    message.writeln("");

    message.writeln("📦 *Product:* ${product.name}");

    if (product.manufacturerBrand.isNotEmpty) {
      message.writeln("🏷️ *Brand:* ${product.manufacturerBrand}");
    }
    message.writeln("📂 *Category:* ${product.category}");

    message.writeln("");
    message.writeln("💰 *PRICING*");
    if (product.hasDiscount()) {
      message.writeln(
        "💸 *Sale Price:* ${product.currency} ${product.getDiscountedPrice().toStringAsFixed(2)}",
      );
      message.writeln(
        "🏷️ *Original Price:* ~${product.currency} ${product.price.toStringAsFixed(2)}~",
      );
      message.writeln(
        "🎯 *You Save:* ${product.getSavingsPercentage().toStringAsFixed(0)}% OFF",
      );
    } else {
      message.writeln(
        "💸 *Price:* ${product.currency} ${product.price.toStringAsFixed(2)}",
      );
    }

    if (_selectedVariantValue != null && product.variants.isNotEmpty) {
      final selectedVariant = product.variants.firstWhere(
        (variant) => variant.value == _selectedVariantValue,
        orElse: () => product.variants.first,
      );
      message.writeln("");
      message.writeln(
        "⚙️ *Selected Option:* ${selectedVariant.name}: ${selectedVariant.value}",
      );
    }

    if (product.shortDescription.isNotEmpty) {
      message.writeln("");
      message.writeln("📝 *Description:* ${product.shortDescription}");
    }

    message.writeln("");
    message.writeln("━━━━━━━━━━━━━━━━━━━━");
    message.writeln(
      "Hi! I'm interested in purchasing this product. Could you please provide more details about availability and delivery options?",
    );
    message.writeln("");
    message.writeln("Thank you! 😊");

    return message.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Details')),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          final product = productProvider.selectedProduct;

          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No product selected'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (productProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: [
                _buildProductImages(product),
                SizedBox(height: 20),
                _buildProductTitle(product),
                SizedBox(height: 5),
                _buildProductSubtitle(product),
                SizedBox(height: 10),
                _buildPriceSection(product),
                SizedBox(height: 10),
                if (product.variants.isNotEmpty) _buildVariantSelector(product),
                if (product.variants.isNotEmpty) SizedBox(height: 20),
                _buildProductDetails(product),
                SizedBox(height: 10),
                _buildProductDescription(product),
                SizedBox(height: 20),
                _buildActionButtons(product, productProvider),
                SizedBox(height: 10),
                _buildDeliveryInfo(),
                SizedBox(height: 40),
                if (_similarProducts.isNotEmpty) _buildSimilarProducts(),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImages(Product product) {
    if (product.images.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
      );
    }

    final carouselItems =
        product.images
            .map(
              (image) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    image.link,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
            )
            .toList();

    return FadingCarousel(height: 180, children: carouselItems);
  }

  Widget _buildProductTitle(Product product) {
    return Text(
      product.name.toUpperCase(),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: wawuColors.primary,
      ),
    );
  }

  Widget _buildProductSubtitle(Product product) {
    return Text(
      product.shortDescription.isNotEmpty
          ? product.shortDescription
          : '${product.manufacturerBrand} - ${product.category}',
      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
    );
  }

  Widget _buildPriceSection(Product product) {
    return Row(
      children: [
        Text(
          '${product.currency} ${product.getDiscountedPrice().toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        if (product.hasDiscount()) ...[
          SizedBox(width: 10),
          Text(
            '${product.currency} ${product.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 13,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
          SizedBox(width: 10),
          Text(
            '${product.getSavingsPercentage().toStringAsFixed(0)}% off',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: wawuColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVariantSelector(Product product) {
    final variants = product.variants;
    if (variants.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Options:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: variants.length,
            itemBuilder: (context, index) {
              final variant = variants[index];
              final isSelected = _selectedVariantValue == variant.value;

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: wawuColors.primary),
                  color: isSelected ? wawuColors.primary : Colors.transparent,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVariantValue = isSelected ? null : variant.value;
                    });
                  },
                  child: Center(
                    child: Text(
                      '${variant.name}: ${variant.value}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white : wawuColors.primary,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails(Product product) {
    return CustomIntroText(text: 'Product Details');
  }

  Widget _buildProductDescription(Product product) {
    return Text(
      product.description.isNotEmpty
          ? product.description
          : 'No description available for this product.',
      style: TextStyle(fontSize: 14, height: 1.5),
    );
  }

  Widget _buildActionButtons(Product product, ProductProvider provider) {
    return Column(
      children: [
        SizedBox(height: 10),
        CustomButton(
          widget: Text('Buy Now', style: TextStyle(color: Colors.white)),
          color: wawuColors.primary,
          function: () => _openWhatsApp(product),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: wawuColors.primary.withAlpha(50),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated Delivery'),
          Text(
            '2-5 Business Days',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIntroText(text: 'Similar Products'),
        SizedBox(height: 20),
        ...List.generate((_similarProducts.length / 2).ceil(), (rowIndex) {
          final firstIndex = rowIndex * 2;
          final secondIndex = firstIndex + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ECard(
                    product: _similarProducts[firstIndex],
                    isMargin: false,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child:
                      secondIndex < _similarProducts.length
                          ? ECard(
                            product: _similarProducts[secondIndex],
                            isMargin: false,
                          )
                          : SizedBox(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
