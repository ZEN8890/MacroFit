import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/storage_services.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CommentPage extends StatefulWidget {
  final String postId;
  final String postUsername;
  final String postContent;

  const CommentPage({
    super.key,
    required this.postId,
    required this.postUsername,
    required this.postContent,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 Properti Unggah Gambar Komentar
  XFile? _selectedCommentImage;
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isCommentPosting = false;

  Future<void> _pickCommentImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedCommentImage = image);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty && _selectedCommentImage == null)
      return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isCommentPosting = true);

    try {
      String commentImageUrl = '';

      // 1. Jika ada gambar, upload ke Firebase Storage folder 'comments'
      if (_selectedCommentImage != null) {
        commentImageUrl = await _storageService.uploadImage(
          _selectedCommentImage!,
          'comments',
        );
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String username = userDoc.exists
          ? (userDoc.data()?['username'] ?? 'User')
          : 'User';

      // 2. Transaksi penyimpanan data ke Firestore Sub-Koleksi Comments
      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
            'uid': user.uid,
            'username': username,
            'content': _commentController.text.trim(),
            'image_url': commentImageUrl, // Menyimpan link gambar komentar
            'timestamp': FieldValue.serverTimestamp(),
          });

      // 3. Update jumlah penghitung komentar di dokumen utama Post
      await _firestore.collection('posts').doc(widget.postId).update({
        'comment_count': FieldValue.increment(1),
      });

      _commentController.clear();
      setState(() {
        _selectedCommentImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membalas: $e')));
    } finally {
      if (mounted) setState(() => _isCommentPosting = false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';

    DateTime commentDate = timestamp.toDate();
    DateTime nowDate = DateTime.now();
    Duration difference = nowDate.difference(commentDate);

    // Menyusun string jam dan menit dengan format 2 digit (misal: 09:05)
    String timeString =
        "${commentDate.hour.toString().padLeft(2, '0')}:${commentDate.minute.toString().padLeft(2, '0')}";

    // Array nama bulan singkat untuk estetika UI
    List<String> months = [
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
    String monthName = months[commentDate.month - 1];

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt lalu';
    } else if (difference.inHours < 24 && commentDate.day == nowDate.day) {
      // Jika masih di hari yang sama, tampilkan jamnya saja (Hari ini)
      return 'Hari ini, $timeString';
    } else if (commentDate.year == nowDate.year) {
      // Jika masih di tahun yang sama tapi beda hari (misal: 14 Mei, 09:15)
      return '${commentDate.day} $monthName, $timeString';
    } else {
      // 🔥 JIKA BEDA TAHUN: Tampilkan tanggal, bulan, tahun, dan jam lengkap ala WhatsApp
      // Hasil akhir misal: 18 Des 2025, 14:30
      return '${commentDate.day} $monthName ${commentDate.year}, $timeString';
    }
  }

  // 🔥 FUNGSI BARU: Menarik Pesan Komentar (Unsend)
  Future<void> _unsendComment(String commentId, String? imageUrl) async {
    bool confirmUnsend =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tarik Balasan'),
            content: const Text('Apakah Anda yakin ingin menarik balasan ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tarik', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmUnsend) return;

    try {
      // 1. Jika pesan yang ditarik punya gambar di Storage, hapus file fisiknya dulu agar hemat cloud
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Gagal hapus gambar komentar saat unsend: $e");
        }
      }

      // 2. Update dokumen di Firestore: Ubah teks konten & kosongkan link gambar
      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .update({
            'content': 'telah menarik pesan ini', // Teks penanda unsend
            'image_url': '', // Hapus gambar
            'is_unsent': true, // Flag tambahan untuk styling UI nanti
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesan berhasil ditarik.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menarik pesan: $e')));
    }
  }

  // 🔥 FUNGSI BARU: Memunculkan Dialog untuk Mengedit Isi Komentar
  Future<void> _editComment(String commentId, String currentContent) async {
    final TextEditingController editController = TextEditingController(
      text: currentContent,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Balasan'),
        content: TextField(
          controller: editController,
          maxLines: null,
          decoration: const InputDecoration(hintText: "Ubah balasan Anda..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              String newContent = editController.text.trim();
              if (newContent.isEmpty) return;

              try {
                // Jalankan perintah update data ke Cloud Firestore
                await _firestore
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .doc(commentId)
                    .update({
                      'content': newContent,
                      'is_edited':
                          true, // Menandai bahwa pesan ini pernah diedit
                    });

                if (context.mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Balasan berhasil diperbarui.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal mengedit: $e')));
              }
            },
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Balasan Thread',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      // 🔥 PERBAIKAN 1: Izinkan Scaffold menyesuaikan diri secara otomatis saat keyboard naik
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Isi Postingan Utama yang Dikomentari
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isDarkMode ? const Color(0xFF161616) : Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.postUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.postContent,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Daftar Komentar Real-time
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada balasan. Mulai obrolan!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentDoc = comments[index];
                      final commentId = commentDoc.id;
                      final commentData =
                          commentDoc.data() as Map<String, dynamic>;

                      String username = commentData['username'] ?? 'User';
                      String content = commentData['content'] ?? '';
                      String? commentImg = commentData['image_url'];
                      String commentUid = commentData['uid'] ?? '';

                      bool isUnsent = commentData['is_unsent'] ?? false;
                      bool isEdited = commentData['is_edited'] ?? false;
                      bool isMyComment =
                          _auth.currentUser != null &&
                          commentUid == _auth.currentUser!.uid;

                      // 🔥 BALUT DENGAN CARD AGAR SINKRON DENGAN TEMA MACROFITTHEME Anda
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baris Atas: Profil Nama, Waktu, dan Menu Tiga Titik
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.teal,
                                        child: Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _formatTimestamp(
                                          commentData['timestamp']
                                              as Timestamp?,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),

                                      // 🔥 TOMBOL MENU TIGA TITIK (Hanya muncul jika ini pesan milik saya DAN belum ditarik)
                                      if (isMyComment && !isUnsent)
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editComment(commentId, content);
                                            } else if (value == 'unsend') {
                                              _unsendComment(
                                                commentId,
                                                commentImg,
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Edit Pesan'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'unsend',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.undo,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Tarik Pesan',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Baris Tengah: Isi Teks Komentar Kustom
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isUnsent ? '$username $content' : content,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isUnsent
                                            ? Colors.grey
                                            : (isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87),
                                        fontStyle: isUnsent
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                  // 🔥 INDIKATOR DIEDIT (Muncul teks kecil 'diedit' jika pesan sudah diubah pengguna)
                                  if (isEdited && !isUnsent)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6.0),
                                      child: Text(
                                        '(edited)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // Baris Bawah: Gambar Lampiran Media Komentar
                              if (!isUnsent &&
                                  commentImg != null &&
                                  commentImg.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      commentImg,
                                      height: 140,
                                      width: 200,
                                      fit: BoxFit.cover,
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
            ),

            const Divider(height: 1, thickness: 1),

            // 🔥 PERBAIKAN 2: Bungkus Bar Input dengan Padding Statis Menggunakan Kontrol Bottom Inset Otomatis
            // Kita menghapus padding manual 'MediaQuery.of(context).viewInsets.bottom' karena sudah ditangani Scaffold
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PREVIEW FOTO KOMENTAR SEBELUM DIKIRIM
                  if (_selectedCommentImage != null)
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          SizedBox(
                            width: 120,
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_selectedCommentImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          if (!_isCommentPosting)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCommentImage = null),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black,
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Baris Input Teks Dan Tombol Kirim
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.image_outlined,
                          color: _selectedCommentImage != null
                              ? theme.primaryColor
                              : Colors.grey,
                        ),
                        onPressed: _isCommentPosting ? null : _pickCommentImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          enabled: !_isCommentPosting,
                          decoration: const InputDecoration(
                            hintText: "Tulis balasan Anda...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isCommentPosting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.primaryColor,
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  Icons.send,
                                  color: theme.primaryColor,
                                ),
                                onPressed: _submitComment,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
