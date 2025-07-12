import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/models/variant.dart';
import 'package:wawu_mobile/screens/wawu_ecommerce_screen/single_package/single_package.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                height: 150,
                                width: isMargin ? 140 : double.infinity,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                              ),
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
                          fontSize: 13,
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
                            fontSize: 12,
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
