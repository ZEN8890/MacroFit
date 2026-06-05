import 'package:flutter/material.dart';

class CreatorHeaderSection extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool englishActive;

  const CreatorHeaderSection({
    super.key,
    required this.userData,
    required this.englishActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    String displayName = userData['username'] ?? 'User MacroFit';
    String handleName = userData['username_handle'] ?? 'user_macrofit';
    String profilePic = userData['profile_picture'] ?? '';
    String bioText = userData['bio'] ?? '';
    String dietCode = userData['diet_code'] ?? 'healthy_lifestyle';

    String displayDiet = dietCode;
    if (dietCode == 'gain_muscle') {
      displayDiet = englishActive ? 'Gain Muscle' : 'Menaikkan Massa Otot';
    } else if (dietCode == 'healthy_lifestyle') {
      displayDiet = englishActive ? 'Healthy Lifestyle' : 'Gaya Hidup Sehat';
    } else if (dietCode == 'keto_diet') {
      displayDiet = englishActive ? 'Keto Diet' : 'Diet Keto';
    } else if (dietCode == 'vegetarian') {
      displayDiet = englishActive ? 'Vegetarian' : 'Vegetarian';
    } else if (dietCode == 'Menurunkan Berat Badan' ||
        dietCode == 'weight_loss') {
      displayDiet = englishActive ? 'Weight Loss' : 'Menurunkan Berat Badan';
    }

    return Padding(
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
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: CircleAvatar(
                    radius: 39,
                    backgroundColor: theme.primaryColor.withOpacity(0.08),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
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
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const Divider(height: 40),
        ],
      ),
    );
  }
}
