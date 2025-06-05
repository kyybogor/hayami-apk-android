import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AkunDetailscreen extends StatefulWidget {
  const AkunDetailscreen({super.key});

  @override
  State<AkunDetailscreen> createState() => _AkunDetailscreenState();
}

class _AkunDetailscreenState extends State<AkunDetailscreen> {
  Map<String, String> userData = {};

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userData = {
        'ID User': prefs.getString('id_user') ?? '',
        'Nama': prefs.getString('nm_user') ?? '',
        'Jabatan': prefs.getString('jabatan') ?? '',
        'Email': prefs.getString('email_user') ?? '',
        'Karyawan': prefs.getString('karyawan') ?? '',
        'Grup': prefs.getString('grup') ?? '',
        'ID Cabang': prefs.getString('id_cabang') ?? '',
        'ID Gudang': prefs.getString('id_gudang') ?? '',
        'Status': prefs.getString('sts') ?? '',
      };
    });
  }

  IconData getIcon(String key) {
    switch (key) {
      case 'ID User':
        return Icons.perm_identity;
      case 'Nama':
        return Icons.person;
      case 'Jabatan':
        return Icons.work_outline;
      case 'Email':
        return Icons.email_outlined;
      case 'Karyawan':
        return Icons.badge_outlined;
      case 'Grup':
        return Icons.group_outlined;
      case 'ID Cabang':
        return Icons.location_city;
      case 'ID Gudang':
        return Icons.store_outlined;
      case 'Status':
        return Icons.verified_user_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = userData['Nama'] ?? '';
    final email = userData['Email'] ?? '';
    final jabatan = userData['Jabatan'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
  centerTitle: true,
  title: const Text(
    'Detail Akun',
    style: TextStyle(color: Colors.white), // Warna teks putih
  ),
  backgroundColor: const Color(0xFF2A5298),
  elevation: 0,
  iconTheme: const IconThemeData(color: Colors.white), // Warna ikon putih
),

      body: userData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // HEADER: Avatar + Nama + Email + Jabatan
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  color: const Color(0xFF2A5298),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF2A5298), size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        jabatan,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // LIST DETAIL USER
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: userData.length,
                    itemBuilder: (context, index) {
                      String key = userData.keys.elementAt(index);
                      String value = userData[key] ?? '';
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(getIcon(key), color: const Color(0xFF2A5298)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    key,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    value.isNotEmpty ? value : '-',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
