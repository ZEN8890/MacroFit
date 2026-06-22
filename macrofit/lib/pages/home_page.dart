import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_services.dart';
import '../widgets/food_input_sheet.dart';
import '../widgets/Daily_Insight_banner.dart';
import '../widgets/welcome_header.dart';
import '../widgets/calorie_target_card.dart';
import '../widgets/nutritional_card.dart';
import '../widgets/water_tracker_card.dart';
import '../widgets/food_verification_card.dart';
import 'profile_page.dart';
import '../widgets/exercise_recommendation_card.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _tempFoodData;
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _directSaveFood(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await DatabaseService().saveFoodLog(user.uid, data);

      if (!mounted) return;
      Notify.success(
        context,
        isEnglishNotifier.value
            ? "Successfully added!"
            : "Berhasil ditambahkan!",
      );
    }
  }

  void _showAddFoodSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const FoodInputSheet(),
    );

    if (!mounted || result == null) return;

    if (result['source'] == 'text') {
      _directSaveFood(result);
    } else {
      setState(() {
        _tempFoodData = result;
      });
      _scrollToBottom();
    }
  }

  void _confirmSaveFood() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _tempFoodData != null && !_isSaving) {
      setState(() => _isSaving = true);

      try {
        await DatabaseService().saveFoodLog(user.uid, _tempFoodData!);
        if (!mounted) return;

        setState(() {
          _tempFoodData = null;
          _isSaving = false;
        });

        Notify.success(
          context,
          isEnglishNotifier.value
              ? "Food logged successfully!"
              : "Makanan berhasil dicatat!",
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        Notify.error(
          context,
          isEnglishNotifier.value
              ? "Failed to log food."
              : "Gagal mencatat makanan.",
        );
      }
    }
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        if (user == null) {
          return Scaffold(
            body: Center(
              child: Text(
                englishActive ? "User not logged in" : "Pengguna belum login",
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Scaffold(
                body: Center(
                  child: Text(
                    englishActive ? "Data not found" : "Data tidak ditemukan",
                  ),
                ),
              );
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String profilePic = userData['profile_picture'] ?? '';

            return Scaffold(
              appBar: AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "MacroFit",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset('assets/Macrofit_logo_only.png', height: 30),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        backgroundImage: profilePic.isNotEmpty
                            ? NetworkImage(profilePic)
                            : null,
                        child: profilePic.isEmpty
                            ? Icon(
                                Icons.account_circle,
                                color: colorScheme.primary,
                                size: 24,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  WelcomeHeader(name: userData['first_name'] ?? "User"),
                  const DailyInsightCarousel(),
                  const SizedBox(height: 25),
                  ExerciseRecommendationCard(
                    dietCode: userData['diet_code'] ?? 'healthy_lifestyle',
                  ),
                  const SizedBox(height: 25),
                  NutritionalCard(userData: userData, uid: user.uid),
                  const SizedBox(height: 15),
                  if (_tempFoodData != null)
                    FoodVerificationCard(
                      data: _tempFoodData!,
                      onConfirm: _confirmSaveFood,
                      onCancel: () => setState(() => _tempFoodData = null),
                    ),
                  WaterTrackerCard(uid: user.uid, userData: userData),
                  const SizedBox(height: 25),

                  _buildSectionTitle(
                    englishActive ? "Calorie Target" : "Target Kalori",
                    colorScheme,
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: DatabaseService().getFilteredFoodLogs(
                      user.uid,
                      'Harian',
                      null,
                    ),
                    builder: (context, logSnapshot) {
                      num totalConsumed = 0;
                      if (logSnapshot.hasData) {
                        for (var doc in logSnapshot.data!.docs) {
                          var foodItem = doc.data() as Map<String, dynamic>;
                          totalConsumed += (foodItem['calories'] ?? 0);
                        }
                      }
                      return CalorieTargetCard(
                        targetCal: (userData['target_calories'] ?? 2000)
                            .toInt(),
                        consumedCal: totalConsumed.toInt(),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showAddFoodSheet(context),
                label: Text(englishActive ? "Log Food" : "Catat Makan"),
                icon: const Icon(Icons.auto_awesome),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            );
          },
        );
      },
    );
  }
}
