import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/wawu_africa_social.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/sign_up.dart';
import 'package:wawu_mobile/widgets/comment_widgets/comment_widgets.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';

class WawuAfricaInstitutionContentScreen extends StatefulWidget {
  const WawuAfricaInstitutionContentScreen({super.key});

  @override
  State<WawuAfricaInstitutionContentScreen> createState() =>
      _WawuAfricaInstitutionContentScreenState();
}

class _WawuAfricaInstitutionContentScreenState
    extends State<WawuAfricaInstitutionContentScreen> {
  late final ScrollController _scrollController;
  final _commentController = TextEditingController();
  Comment? _replyingToComment;
  final FocusNode _commentFocusNode = FocusNode();

  Color _appBarBgColor = Colors.transparent;
  Color _appBarItemColor = Colors.white;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WawuAfricaProvider>(context, listen: false);
      final contentId = provider.selectedInstitutionContent?.id;
      if (contentId != null) {
        provider.fetchCommentsAndLikes(contentId);
        provider.listenToRealtimeUpdates(contentId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();

    final provider = Provider.of<WawuAfricaProvider>(context, listen: false);
    final contentId = provider.selectedInstitutionContent?.id;
    if (contentId != null) {
      provider.stopListeningToRealtimeUpdates(contentId);
    }

    super.dispose();
  }

  void _scrollListener() {
    const scrollThreshold = 150.0;
    double opacity = (_scrollController.offset / scrollThreshold).clamp(
      0.0,
      1.0,
    );
    Color itemColor = opacity > 0.5 ? Colors.black : Colors.white;

    if (opacity != (_appBarBgColor.opacity) || itemColor != _appBarItemColor) {
      setState(() {
        _appBarBgColor = Colors.white.withOpacity(opacity);
        _appBarItemColor = itemColor;
      });
    }
  }

  Future<void> _handleRegistration() async {
    // MODIFIED: Use the new authentication helper
    _handleAuthenticatedAction(() async {
      setState(() => _isRegistering = true);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final wawuProvider = Provider.of<WawuAfricaProvider>(
        context,
        listen: false,
      );
      final planProvider = Provider.of<PlanProvider>(context, listen: false);

      final contentId = wawuProvider.selectedInstitutionContent?.id;
      if (contentId == null) {
        CustomSnackBar.show(
          context,
          message: 'Content ID is missing.',
          isError: true,
        );
        setState(() => _isRegistering = false);
        return;
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'No internet connection. Please try again later.',
            isError: true,
          );
        }
        setState(() => _isRegistering = false);
        return;
      }

      try {
        int getRoleId(String? roleName) {
          switch (roleName?.toUpperCase()) {
            case 'BUYER':
              return 1;
            case 'PROFESSIONAL':
              return 2;
            case 'ARTISAN':
              return 3;
            default:
              return 0;
          }
        }

        final int roleId = getRoleId(userProvider.currentUser!.role);

        await planProvider.fetchUserSubscriptionDetails(
          userProvider.currentUser!.uuid,
          roleId,
        );

        if (!mounted) return;

        if (planProvider.hasActiveSubscription) {
          await wawuProvider.registerForContent(contentId);
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Request sent\nYou will be contacted soon',
            );
          }
        } else {
          final bool? wantsToSubscribe = await _showSubscriptionDialog(
            planProvider,
          );

          if (wantsToSubscribe == true && mounted) {
            await planProvider.purchaseSubscription(
              planUuid: '',
              userId: userProvider.currentUser!.uuid,
            );
            CustomSnackBar.show(
              context,
              message:
                  'Once your subscription is confirmed, please tap "Send a request" again.',
            );
          }
        }
      } catch (e) {
        String errorMessage =
            'An error occurred. Please check your connection and try again.';
        bool isError = true;
        if (e.toString().toLowerCase().contains('user is already registered')) {
          errorMessage = 'You have already sent a request for this content.';
          isError = false;
        }
        if (mounted) {
          CustomSnackBar.show(context, message: errorMessage, isError: isError);
        }
      } finally {
        if (mounted) {
          setState(() => _isRegistering = false);
        }
      }
    });
  }

  Future<bool?> _showSubscriptionDialog(PlanProvider planProvider) async {
    if (!planProvider.isIapInitialized) {
      await planProvider.initializeIAP();
    }
    ProductDetails? product;
    if (planProvider.iapProducts.isNotEmpty) {
      product = planProvider.iapProducts.first;
    }
    return showModalBottomSheet<bool>(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Subscription Required'),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    product != null
                        ? 'Subscribe for ${product.price}'
                        : 'Subscribe',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
    );
  }

  // NEW: A reusable function to check for authentication before performing an action.
  void _handleAuthenticatedAction(VoidCallback onAuthenticated) {
    // Use listen: false because we are in a method, not the build function.
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser != null) {
      // If the user is logged in, execute the action they intended to perform.
      onAuthenticated();
    } else {
      // If the user is not logged in, show a message and navigate to the SignUp screen.
      CustomSnackBar.show(
        context,
        message: 'Please sign up or log in to continue.',
        isError: true,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUp()),
      );
    }
  }

  void _postComment() {
    // MODIFIED: Wrap the entire post logic in the authentication check.
    _handleAuthenticatedAction(() {
      final provider = Provider.of<WawuAfricaProvider>(context, listen: false);
      final contentId = provider.selectedInstitutionContent?.id;
      final text = _commentController.text.trim();

      if (text.isEmpty || contentId == null) return;

      final parentId = _replyingToComment?.id;
      provider
          .postComment(
            comment: text,
            contentId: contentId,
            parentCommentId: parentId,
          )
          .then((_) {
            _commentController.clear();
            FocusScope.of(context).unfocus();
            setState(() {
              _replyingToComment = null;
            });
          })
          .catchError((_) {
            CustomSnackBar.show(
              context,
              message: 'Failed to send comment.',
              isError: true,
            );
          });
    });
  }

  void _onReplyPressed(Comment comment) {
    setState(() {
      _replyingToComment = comment;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WawuAfricaProvider>();
    final currentUser = context.watch<UserProvider>().currentUser;
    final content = provider.selectedInstitutionContent;
    final institution = provider.selectedInstitution;

    if (content == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No content selected. Please go back.')),
      );
    }

    final markdownStyle = MarkdownStyleSheet.fromTheme(Theme.of(context));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _appBarBgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _appBarItemColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _appBarBgColor.opacity > 0.5 ? content.name : '',
          style: TextStyle(color: _appBarItemColor, fontSize: 14),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToComment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Replying to @${_replyingToComment!.user.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          CommentInputWidget(
            controller: _commentController,
            focusNode: _commentFocusNode,
            isLoading: provider.isSendingComment,
            onSendPressed: _postComment,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRegistering ? null : _handleRegistration,
        backgroundColor: const Color(0xFFF50057),
        icon:
            _isRegistering
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : (institution?.profileImageUrl.isNotEmpty ?? false)
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: institution!.profileImageUrl,
                    height: 24,
                    width: 24,
                    fit: BoxFit.cover,
                  ),
                )
                : const Icon(Icons.send, color: Colors.white),
        label: const Text(
          'Send a request',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: content.imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LikeButton(
                        likeCount: provider.getLikeCount('content', content.id),
                        isLiked: provider.isLikedByUser('content', content.id),
                        // MODIFIED: Wrap the like action in the authentication check.
                        onPressed:
                            () => _handleAuthenticatedAction(() {
                              provider.toggleLike('content', content.id);
                            }),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        content.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Requirements'),
                      MarkdownBody(
                        data: content.requirements,
                        styleSheet: markdownStyle,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Key Benefits'),
                      MarkdownBody(
                        data: content.keyBenefits,
                        styleSheet: markdownStyle,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Remarks'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          provider.isLoading && provider.comments.isEmpty
              ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
              : provider.hasError && provider.comments.isEmpty
              ? SliverFillRemaining(
                child: Center(child: Text(provider.errorMessage!)),
              )
              : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  Widget buildCommentTree(Comment comment, {int depth = 0}) {
                    final loggedInUserUUID = currentUser?.uuid;
                    final commentAuthorUUID = comment.user.uuid;

                    final bool isAuthor =
                        (loggedInUserUUID != null &&
                            commentAuthorUUID != null &&
                            loggedInUserUUID.isNotEmpty &&
                            loggedInUserUUID == commentAuthorUUID);

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: (depth * 40.0)),
                          child: CommentWidget(
                            comment: comment,
                            likeCount: provider.getLikeCount(
                              'comment',
                              comment.id,
                            ),
                            isLiked: provider.isLikedByUser(
                              'comment',
                              comment.id,
                            ),
                            isAuthor: isAuthor,
                            // MODIFIED: Wrap the like action in the authentication check.
                            onLikePressed:
                                () => _handleAuthenticatedAction(() {
                                  provider.toggleLike('comment', comment.id);
                                }),
                            onReplyPressed: _onReplyPressed,
                            onDeletePressed: () {
                              provider.deleteComment(comment.id);
                            },
                          ),
                        ),
                        ...comment.replies.map(
                          (reply) => buildCommentTree(reply, depth: depth + 1),
                        ),
                      ],
                    );
                  }

                  return buildCommentTree(provider.comments[index]);
                }, childCount: provider.comments.length),
              ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
