import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/screens/wawu_ecommerce_screen/single_package/single_package.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

class Product {
  final String id;
  final String name;
  final String primaryImageUrl;
  final double price;
  final double? discountPrice; // Optional discount price
  final String currency;

  Product({
    required this.id,
    required this.name,
    required this.primaryImageUrl,
    required this.price,
    this.discountPrice,
    required this.currency,
  });

  bool hasDiscount() {
    return discountPrice != null && discountPrice! < price;
  }

  double getDiscountedPrice() {
    return discountPrice ?? price;
  }
}

class ECard extends StatelessWidget {
  final Product product;
  final bool isMargin;

  const ECard({super.key, required this.product, this.isMargin = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Update the provider state with the selected product
        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).selectProduct(product.id);

        // Navigate to the single package screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SinglePackage()),
        );
      },
      child: Container(
        width: isMargin ? 140 : double.infinity,
        height: 150,
        margin: EdgeInsets.only(right: isMargin ? 10.0 : 0.0),
        child: Column(
          // Use `children` directly, `spacing` is not a Column property
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    product.primaryImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: product.primaryImageUrl,
                          height: 150,
                          width: isMargin ? 140 : double.infinity,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                height: 150,
                                width: isMargin ? 140 : double.infinity,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget: (context, url, error) {
                            return Container(
                              height: 150,
                              width: isMargin ? 140 : double.infinity,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            );
                          },
                        )
                        : Container(
                          height: 150,
                          width: isMargin ? 140 : double.infinity,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
              ),
            ),
            // Replaced Column's `spacing` with SizedBox for consistent spacing
            const SizedBox(height: 5.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  // Replaced Row's `spacing` with SizedBox for consistent spacing
                  children: [
                    Flexible(
                      child: Text(
                        '${product.currency}${product.getDiscountedPrice().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.hasDiscount())
                      const SizedBox(width: 10.0), // Spacing between prices
                    if (product.hasDiscount())
                      Flexible(
                        child: Text(
                          '${product.currency}${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            decoration: TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10.0), // Spacing below prices
                Text(
                  product.name,
                  maxLines: 2,
                  style: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
