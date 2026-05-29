import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About MacroFit"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo dengan dekorasi kartu
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  'assets/Macrofit_logo_only.png',
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "MacroFit",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Nutrition & Wellness Tracker",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Detail Informasi
            const Divider(),
            _buildInfoTile(Icons.code, "App Developer", "Steven Gunawan"),
            _buildInfoTile(
              Icons.article_outlined,
              "Research Paper",
              "Kevin Reynald",
            ),
            _buildInfoTile(Icons.update, "Version", "1.0.0"),
            const Divider(),

            const SizedBox(height: 20),
            const Text(
              "© 2026 Final Thesis Project",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper agar kode lebih rapi
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
