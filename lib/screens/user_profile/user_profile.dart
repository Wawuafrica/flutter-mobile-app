import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/user.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';

// Import your GigCard component
// import 'path/to/your/gig_card.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.viewedUser;
    final name =
        user != null ? '${user.firstName} ${user.lastName}' : 'Unknown';
    final profileImage =
        user?.profileImage ?? 'assets/images/other/avatar.webp';
    final role = user?.role ?? 'Seller';
    // final isOnline = user?.status == 'ONLINE'; // Assuming status field indicates online status

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: wawuColors.primary,
                image:
                    user?.coverImage != null && user!.coverImage!.isNotEmpty
                        ? DecorationImage(
                          image: CachedNetworkImageProvider(user.coverImage!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  // Profile Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipOval(
                      child:
                          profileImage.startsWith('http')
                              ? CachedNetworkImage(
                                imageUrl: profileImage,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Image.asset(
                                      'assets/images/other/avatar.webp',
                                      fit: BoxFit.cover,
                                    ),
                              )
                              : Image.asset(profileImage, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Name and Role
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Verified Badge
                  if (user?.status ==
                      'VERIFIED') // Assuming status or another field indicates verification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: wawuColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Verified Seller',
                          style: TextStyle(
                            fontSize: 14,
                            color: wawuColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      // Assuming a rating field in user model; otherwise, this can be adjusted
                      final rating =
                          user?.profileCompletionRate != null
                              ? (user!.profileCompletionRate! / 20).floor()
                              : 4;
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: wawuColors.primary,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Social Media Icons
                  if (user?.additionalInfo?.socialHandles != null &&
                      user!.additionalInfo!.socialHandles!.isNotEmpty)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            user.additionalInfo!.socialHandles!.entries.map((
                              entry,
                            ) {
                              IconData icon;
                              switch (entry.key.toLowerCase()) {
                                case 'twitter':
                                  icon = FontAwesomeIcons.twitter;
                                  break;
                                case 'facebook':
                                  icon = FontAwesomeIcons.facebook;
                                  break;
                                case 'linkedin':
                                  icon = FontAwesomeIcons.linkedin;
                                  break;
                                case 'instagram':
                                  icon = FontAwesomeIcons.instagram;
                                  break;
                                default:
                                  icon = FontAwesomeIcons.link;
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: _buildSocialIcon(
                                  icon,
                                  wawuColors.primary,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats Section
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Text(
            //             'Total Gigs Sold',
            //             style: TextStyle(
            //               fontSize: 14,
            //               color: Colors.black87,
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //           const SizedBox(height: 4),
            //           Text(
            //             user?.additionalInfo != null &&
            //                     user!.additionalInfo!.bio != null
            //                 ? '2200' // Replace with actual data if available in user model
            //                 : '0',
            //             style: const TextStyle(
            //               fontSize: 16,
            //               color: Colors.black,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ],
            //       ),
            //       Column(
            //         crossAxisAlignment: CrossAxisAlignment.end,
            //         children: [
            //           const Text(
            //             'Total Gigs bought',
            //             style: TextStyle(
            //               fontSize: 14,
            //               color: Colors.black87,
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //           const SizedBox(height: 4),
            //           Text(
            //             user?.additionalInfo != null &&
            //                     user!.additionalInfo!.bio != null
            //                 ? '700' // Replace with actual data if available in user model
            //                 : '0',
            //             style: const TextStyle(
            //               fontSize: 16,
            //               color: Colors.black,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 24),
            // Gigs Section
            // const Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 20),
            //   child: Text(
            //     'Gigs',
            //     style: TextStyle(
            //       fontSize: 18,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.black,
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 12),
            // // Gig Cards
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: Column(
            //     children:
            //         user?.portfolios != null && user!.portfolios!.isNotEmpty
            //             ? user.portfolios!
            //                 .map(
            //                   (portfolio) => Padding(
            //                     padding: const EdgeInsets.only(bottom: 12),
            //                     child:
            //                         GigCard(gig: portfolio), // Pass portfolio data to GigCard if needed
            //                   ),
            //                 )
            //                 .toList()
            //             : [const Text('No gigs available.')],
            //   ),
            // ),
            // const SizedBox(height: 24),
            // Skills Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Skills',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    user?.additionalInfo?.skills != null &&
                            user!.additionalInfo!.skills!.isNotEmpty
                        ? user.additionalInfo!.skills!
                            .map(
                              (skill) => _buildSkillChip(
                                skill,
                                Colors.pink.shade100,
                                Colors.pink,
                              ),
                            )
                            .toList()
                        : [const Text('No skills listed.')],
              ),
            ),
            const SizedBox(height: 24),
            // Certification Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Certification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children:
                    user?.additionalInfo?.professionalCertification != null &&
                            user!
                                .additionalInfo!
                                .professionalCertification!
                                .isNotEmpty
                        ? user.additionalInfo!.professionalCertification!
                            .map(
                              (cert) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCertificationCard(cert),
                              ),
                            )
                            .toList()
                        : [const Text('No certifications listed.')],
              ),
            ),
            const SizedBox(height: 24),
            // Contact Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactField(
                    'Phone Number',
                    user?.phoneNumber ?? 'Not available',
                  ),
                  const SizedBox(height: 16),
                  _buildContactField('Email', user?.email ?? 'Not available'),
                  const SizedBox(height: 16),
                  _buildContactField(
                    'Location',
                    user?.location ?? 'Not available',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: FaIcon(icon, color: Colors.white, size: 20)),
    );
  }

  Widget _buildSkillChip(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCertificationCard([ProfessionalCertification? cert]) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), wawuColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert?.name ?? 'Not available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cert?.organization ?? 'Not available',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildContactField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.black)),
      ],
    );
  }
}

class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.viewedUser;
    final name =
        user != null ? '${user.firstName} ${user.lastName}' : 'Unknown';
    final profileImage =
        user?.profileImage ?? 'assets/images/other/avatar.webp';
    final role = user?.role ?? 'Buyer';
    // final isOnline =
    //     user?.status ==
    //     'ONLINE'; // Assuming status field indicates online status

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: wawuColors.primary,
                image:
                    user?.coverImage != null && user!.coverImage!.isNotEmpty
                        ? DecorationImage(
                          image: CachedNetworkImageProvider(user.coverImage!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  // Profile Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipOval(
                      child:
                          profileImage.startsWith('http')
                              ? CachedNetworkImage(
                                imageUrl: profileImage,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Image.asset(
                                      'assets/images/other/avatar.webp',
                                      fit: BoxFit.cover,
                                    ),
                              )
                              : Image.asset(profileImage, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Name and Role
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Verified Badge
                  if (user?.status ==
                      'VERIFIED') // Assuming status or another field indicates verification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: wawuColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Verified Buyer',
                          style: TextStyle(
                            fontSize: 14,
                            color: wawuColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Contact Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactField(
                    'Phone Number',
                    user?.phoneNumber ?? 'Not available',
                  ),
                  const SizedBox(height: 16),
                  _buildContactField('Email', user?.email ?? 'Not available'),
                  const SizedBox(height: 16),
                  _buildContactField(
                    'Location',
                    user?.location ?? 'Not available',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.black)),
      ],
    );
  }
}

// // Placeholder GigCard widget - replace with your actual implementation
// class GigCard extends StatelessWidget {
//   const GigCard({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: 200,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: const Center(child: Text('Gig Card Placeholder')),
//     );
//   }
// }
