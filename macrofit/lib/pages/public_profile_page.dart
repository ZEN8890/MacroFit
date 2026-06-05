import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/global_state.dart';
import '../widgets/creator_header_section.dart';
import '../widgets/creator_recipes_tab.dart';
import '../widgets/creator_posts_tab.dart'; // 🟢 UBAH IMPOR: Memanggil komponen PostsTab baru

class PublicProfilePage extends StatelessWidget {
  final String targetUserId;

  const PublicProfilePage({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              englishActive ? 'Creator Profile' : 'Profil Kreator',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            elevation: 0,
            backgroundColor: theme.appBarTheme.backgroundColor,
            foregroundColor: theme.appBarTheme.foregroundColor,
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(targetUserId)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return Center(
                  child: Text(
                    englishActive
                        ? 'Profile data not found or has been deleted.'
                        : 'Data profil tidak ditemukan atau telah dihapus.',
                  ),
                );
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;

              return DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: CreatorHeaderSection(
                          userData: userData,
                          englishActive: englishActive,
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            labelColor: theme.primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: theme.primaryColor,
                            tabs: [
                              Tab(
                                icon: const Icon(Icons.restaurant, size: 18),
                                text: englishActive ? "Recipes" : "Resep",
                              ),
                              // 🟢 FIX TAB UTAMA: Mengubah Balasan menjadi Postingan Sosial
                              Tab(
                                icon: const Icon(
                                  Icons.dynamic_feed_rounded,
                                  size: 18,
                                ),
                                text: englishActive ? "Posts" : "Postingan",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      CreatorRecipesTab(
                        targetUserId: targetUserId,
                        englishActive: englishActive,
                      ),
                      // 🟢 FIX KONTEN TAB: Memanggil widget list postingan buatan kreator
                      CreatorPostsTab(
                        targetUserId: targetUserId,
                        englishActive: englishActive,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
