import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class PublicProfilePage extends StatelessWidget {
  final String targetUserId;

  const PublicProfilePage({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus seluruh halaman Public Profile dengan ValueListenableBuilder
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
              String displayName = userData['username'] ?? 'User MacroFit';
              String handleName =
                  userData['username_handle'] ?? 'user_macrofit';
              String profilePic = userData['profile_picture'] ?? '';
              String bioText = userData['bio'] ?? '';
              String dietCode = userData['diet_code'] ?? 'healthy_lifestyle';

              // 🟢 DINAMIS TRANSLASI TARGET DIET
              String displayDiet = dietCode;
              if (dietCode == 'gain_muscle') {
                displayDiet = englishActive
                    ? 'Gain Muscle'
                    : 'Menaikkan Massa Otot';
              }
              if (dietCode == 'healthy_lifestyle') {
                displayDiet = englishActive
                    ? 'Healthy Lifestyle'
                    : 'Gaya Hidup Sehat';
              }
              if (dietCode == 'keto_diet') {
                displayDiet = englishActive ? 'Keto Diet' : 'Diet Keto';
              }
              if (dietCode == 'vegetarian') {
                displayDiet = englishActive ? 'Vegetarian' : 'Vegetarian';
              }
              if (dietCode == 'Menurunkan Berat Badan' ||
                  dietCode == 'weight_loss') {
                displayDiet = englishActive
                    ? 'Weight Loss'
                    : 'Menurunkan Berat Badan';
              }

              return DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundColor: theme.primaryColor,
                                    child: CircleAvatar(
                                      radius: 42,
                                      backgroundColor:
                                          theme.scaffoldBackgroundColor,
                                      child: CircleAvatar(
                                        radius: 39,
                                        backgroundColor: theme.primaryColor
                                            .withOpacity(0.08),
                                        backgroundImage: profilePic.isNotEmpty
                                            ? NetworkImage(profilePic)
                                            : null,
                                        child: profilePic.isEmpty
                                            ? Icon(
                                                Icons.person,
                                                size: 40,
                                                color: theme.primaryColor,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@$handleName',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            "Target: $displayDiet",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Text(
                                englishActive ? 'About Me:' : 'Tentang Saya:',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bioText.isNotEmpty
                                    ? bioText
                                    : (englishActive
                                          ? "This creator hasn't written a bio description in MacroFit yet."
                                          : "Kreator ini belum menuliskan deskripsi bio di aplikasi MacroFit."),
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const Divider(height: 40),
                            ],
                          ),
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
                              Tab(
                                icon: const Icon(
                                  Icons.mode_comment_outlined,
                                  size: 18,
                                ),
                                text: englishActive ? "Replies" : "Balasan",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      // TAB 1: DAFTAR RESEP YANG DIPOSTING OLEH USER INI
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('recipes')
                            .where('userId', isEqualTo: targetUserId)
                            .where('type', isEqualTo: 'Community')
                            .snapshots(),
                        builder: (context, recipeSnapshot) {
                          if (recipeSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!recipeSnapshot.hasData ||
                              recipeSnapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                englishActive
                                    ? 'This creator hasn\'t shared any recipes yet.'
                                    : 'Kreator ini belum membagikan resep apa pun.',
                              ),
                            );
                          }

                          final docs = recipeSnapshot.data!.docs;

                          return ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final recipeData =
                                  docs[index].data() as Map<String, dynamic>;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.primaryColor
                                          .withOpacity(0.1),
                                      child: Icon(
                                        Icons.restaurant_menu,
                                        color: theme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      recipeData['title'] ??
                                          (englishActive
                                              ? 'Untitled Recipe'
                                              : 'Resep Tanpa Nama'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${recipeData['calories'] ?? 0} Kcal',
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // TAB 2: HISTORI AKTIVITAS BALASAN/REPLIES DENGAN TIMESTAMP RAPI
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('user_comments_history')
                            .where('userId', isEqualTo: targetUserId)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, historySnapshot) {
                          if (historySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!historySnapshot.hasData ||
                              historySnapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                englishActive
                                    ? 'This creator hasn\'t written any reviews or comments yet.'
                                    : 'Kreator ini belum pernah menulis ulasan atau komentar.',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }

                          final historyDocs = historySnapshot.data!.docs;

                          return ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: historyDocs.length,
                            itemBuilder: (context, index) {
                              final hData =
                                  historyDocs[index].data()
                                      as Map<String, dynamic>;
                              int reviewRating = hData['rating'] ?? 5;
                              String recipeTitle =
                                  hData['recipeTitle'] ??
                                  (englishActive ? 'Recipe' : 'Resep');

                              String timeDisplay = '...';
                              if (hData['timestamp'] != null) {
                                final Timestamp ts =
                                    hData['timestamp'] as Timestamp;
                                final DateTime dt = ts.toDate();

                                final List<String> monthsID = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'Mei',
                                  'Jun',
                                  'Jul',
                                  'Agu',
                                  'Sep',
                                  'Okt',
                                  'Nov',
                                  'Des',
                                ];
                                final List<String> monthsEN = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                  'Jul',
                                  'Aug',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Dec',
                                ];
                                final List<String> activeMonths = englishActive
                                    ? monthsEN
                                    : monthsID;

                                final String minutes = dt.minute < 10
                                    ? '0${dt.minute}'
                                    : '${dt.minute}';
                                timeDisplay =
                                    '${dt.day} ${activeMonths[dt.month - 1]} ${dt.year}, ${dt.hour}:$minutes';
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 0.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? Colors.white10
                                        : Colors.black.withOpacity(0.04),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.reply_rounded,
                                                  color: Colors.grey,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    englishActive
                                                        ? 'Reviewed in "$recipeTitle"'
                                                        : 'Mengulas di "$recipeTitle"',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(5, (
                                              starIndex,
                                            ) {
                                              return Icon(
                                                starIndex < reviewRating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 13,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        hData['commentText'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          timeDisplay,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
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
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
