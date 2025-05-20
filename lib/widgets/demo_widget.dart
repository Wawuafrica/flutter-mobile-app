import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/blog_provider.dart';
import '../providers/product_provider.dart';

/// Demo widget showing how to use providers with loading/error states
class DemoWidget extends StatefulWidget {
  const DemoWidget({Key? key}) : super(key: key);

  @override
  State<DemoWidget> createState() => _DemoWidgetState();
}

class _DemoWidgetState extends State<DemoWidget> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlogProvider>(context, listen: false).fetchFeaturedPosts();
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchFeaturedProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wawu Demo')),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [_BlogTab(), _ProductsTab()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Blog'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
        ],
      ),
    );
  }
}

class _BlogTab extends StatelessWidget {
  const _BlogTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BlogProvider>(
      builder: (context, blogProvider, child) {
        // Show loading state
        if (blogProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (blogProvider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  blogProvider.errorMessage ?? 'An error occurred',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => blogProvider.fetchFeaturedPosts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show empty state
        if (blogProvider.featuredPosts.isEmpty) {
          return const Center(child: Text('No blog posts available'));
        }

        // Show blog posts
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: blogProvider.featuredPosts.length,
          itemBuilder: (context, index) {
            final post = blogProvider.featuredPosts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured image
                  if (post.featuredImageUrl != null)
                    Image.network(
                      post.featuredImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 80),
                          ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.getExcerpt(100),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  post.authorAvatarUrl != null
                                      ? NetworkImage(post.authorAvatarUrl!)
                                      : null,
                              child:
                                  post.authorAvatarUrl == null
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            Text(post.authorName),
                            const Spacer(),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.publishedAt.day}/${post.publishedAt.month}/${post.publishedAt.year}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Show loading state
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (productProvider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  productProvider.errorMessage ?? 'An error occurred',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => productProvider.fetchFeaturedProducts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show empty state
        if (productProvider.featuredProducts.isEmpty) {
          return const Center(child: Text('No products available'));
        }

        // Show products in a grid
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: productProvider.featuredProducts.length,
          itemBuilder: (context, index) {
            final product = productProvider.featuredProducts[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Expanded(
                    child: Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.network(
                            product.getMainImageUrl(),
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 80),
                                ),
                          ),
                        ),
                        if (product.hasDiscount())
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.discountType == 'percentage'
                                    ? '-${product.discountValue!.toInt()}%'
                                    : '-\$${product.discountValue!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (product.hasDiscount()) ...[
                              Text(
                                '\$${product.getDiscountedPrice().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ] else
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            productProvider.addToCart(product.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 36),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Add to Cart'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
