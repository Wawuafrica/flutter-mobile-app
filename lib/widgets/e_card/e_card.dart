import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/models/variant.dart';
import 'package:wawu_mobile/screens/wawu_ecommerce_screen/single_package/single_package.dart';

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
        height: 170,
        margin: EdgeInsets.only(right: isMargin ? 10.0 : 0.0),
        child: Column(
          spacing: 5.0,
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
                        ? Image.network(
                          product.primaryImageUrl,
                          height: 160,
                          width: isMargin ? 140 : double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 160,
                              width: isMargin ? 140 : double.infinity,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 160,
                              width: isMargin ? 140 : double.infinity,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              ),
                            );
                          },
                        )
                        : Container(
                          height: 160,
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
            Column(
              spacing: 10.0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 10.0,
                  children: [
                    Flexible(
                      child: Text(
                        '${product.currency}${product.getDiscountedPrice().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.hasDiscount())
                      Flexible(
                        child: Text(
                          '${product.currency}${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            decoration: TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                Text(
                  product.name,
                  maxLines: 2,
                  style: TextStyle(
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
