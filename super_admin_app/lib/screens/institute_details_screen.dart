import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/b2_view_service.dart';

class InstituteDetailsScreen extends StatefulWidget {
  final String instituteId;
  final String instituteName;

  const InstituteDetailsScreen({
    super.key,
    required this.instituteId,
    required this.instituteName,
  });

  @override
  State<InstituteDetailsScreen> createState() => _InstituteDetailsScreenState();
}

class _InstituteDetailsScreenState extends State<InstituteDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.instituteName),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xCCFFFFFF),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Students'),
            Tab(text: 'Attendance'),
            Tab(text: 'GPS'),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFF4F7FC),
        child: TabBarView(
          controller: _tabController,
          children: [
            _overviewTab(),
            _studentsTab(),
            _attendanceTab(),
            _gpsTab(),
          ],
        ),
      ),
    );
  }

  Widget _overviewTab() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('institutes').doc(widget.instituteId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _infoCard('Institute ID', widget.instituteId),
            _infoCard('Name', (data['name'] ?? '').toString()),
            _infoCard('Code', (data['instituteCode'] ?? '').toString()),
            _infoCard('City', (data['city'] ?? '').toString()),
            _infoCard('Students', (data['studentCount'] ?? 0).toString()),
            _infoCard('Admins', (data['userCount'] ?? 0).toString()),
          ],
        );
      },
    );
  }

  Widget _studentsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('institutes')
          .doc(widget.instituteId)
          .collection('students')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No students'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data();
            final name = (d['name'] ?? 'Unknown').toString();
            final roll = (d['userId'] ?? '').toString();
            return Card(
              child: ListTile(
                title: Text(name),
                subtitle: Text('Roll: $roll'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentHistoryScreen(
                        instituteId: widget.instituteId,
                        studentName: name,
                        rollNumber: roll,
                        studentDocId: docs[index].id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _attendanceTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('institutes')
          .doc(widget.instituteId)
          .collection('attendance')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No attendance records'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data();
            final subject = (d['subject'] ?? '').toString();
            final roll = (d['rollNumber'] ?? d['studentId'] ?? '').toString();
            final ts = d['timestamp'];
            final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
            final when = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
            final path = (d['verificationSelfie'] ?? d['photoPath'] ?? '').toString();

            return Card(
              child: ListTile(
                title: Text('Roll $roll - $subject'),
                subtitle: Text(when),
                trailing: SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: path.isEmpty
                        ? const Icon(Icons.image_not_supported_outlined)
                        : FutureBuilder<String>(
                            future: B2ViewService.getTemporaryDownloadUrl(path),
                            builder: (context, snap) {
                              if (!snap.hasData || snap.data!.isEmpty) {
                                return const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(Icons.photo),
                                );
                              }
                              final url = snap.data!;
                              return _PhotoThumb(url: url);
                            },
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _gpsTab() {
    final usersStream = FirebaseFirestore.instance
        .collection('institutes')
        .doc(widget.instituteId)
        .collection('users')
        .snapshots();

    final gpsStream = FirebaseFirestore.instance
        .collection('institutes')
        .doc(widget.instituteId)
        .collection('gps_settings')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, usersSnap) {
        final usersMap = <String, Map<String, dynamic>>{};
        for (final u in (usersSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[])) {
          usersMap[u.id] = u.data();
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: gpsStream,
          builder: (context, gpsSnap) {
            final docs = gpsSnap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No GPS configurations found'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final isLegacyShared = doc.id == 'config';
                final adminId = (data['adminId'] ?? doc.id).toString();
                final adminData = usersMap[adminId] ?? <String, dynamic>{};
                final adminName = isLegacyShared
                    ? 'Shared (Legacy)'
                    : (adminData['name'] ?? 'Admin $adminId').toString();
                final email = (adminData['email'] ?? '').toString();
                final lat = (data['latitude'] ?? '-').toString();
                final lng = (data['longitude'] ?? '-').toString();
                final radius = (data['radius'] ?? '-').toString();
                final locked = data['isLocked'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: locked ? Colors.orange.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                      child: Icon(locked ? Icons.lock : Icons.lock_open, color: locked ? Colors.orange.shade800 : Colors.green.shade700),
                    ),
                    title: Text(adminName),
                    subtitle: Text(
                      '${email.isEmpty ? 'No email' : email}\nLat: $lat | Lng: $lng | Radius: ${radius}m',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      locked ? 'Locked' : 'Unlocked',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: locked ? Colors.orange.shade900 : Colors.green.shade800,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }
}

class StudentHistoryScreen extends StatelessWidget {
  final String instituteId;
  final String studentName;
  final String rollNumber;
  final String studentDocId;

  const StudentHistoryScreen({
    super.key,
    required this.instituteId,
    required this.studentName,
    required this.rollNumber,
    required this.studentDocId,
  });

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _records() async {
    final byRoll = await FirebaseFirestore.instance
        .collection('institutes')
        .doc(instituteId)
        .collection('attendance')
        .where('rollNumber', isEqualTo: rollNumber)
        .get();

    final byStudent = await FirebaseFirestore.instance
        .collection('institutes')
        .doc(instituteId)
        .collection('attendance')
        .where('studentId', isEqualTo: studentDocId)
        .get();

    final map = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in byRoll.docs) {
      map[d.id] = d;
    }
    for (final d in byStudent.docs) {
      map[d.id] = d;
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(studentName)),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _records(),
        builder: (context, snapshot) {
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) return const Center(child: Text('No records'));

          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final d in docs) {
            final data = d.data();
            final subject = (data['subject'] ?? 'general_subject').toString();
            grouped.putIfAbsent(subject, () => []);
            grouped[subject]!.add(data);
          }

          final subjects = grouped.keys.toList()..sort();
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final list = grouped[subject]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(subject),
                  subtitle: Text('${list.length} daily entries'),
                  children: list.map((e) {
                    final ts = e['timestamp'];
                    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
                    final dateText = DateFormat('dd MMM yyyy').format(dt);
                    final timeText = DateFormat('hh:mm a').format(dt);
                    final path = (e['verificationSelfie'] ?? e['photoPath'] ?? '').toString();

                    return ListTile(
                      title: Text(dateText),
                      subtitle: Text(timeText),
                      trailing: SizedBox(
                        width: 56,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: path.isEmpty
                              ? const Icon(Icons.image_not_supported)
                              : FutureBuilder<String>(
                                  future: B2ViewService.getTemporaryDownloadUrl(path),
                                  builder: (context, snap) {
                                    if (!snap.hasData || snap.data!.isEmpty) {
                                      return const Icon(Icons.photo);
                                    }
                                    return _PhotoThumb(url: snap.data!);
                                  },
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  const _PhotoThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image_outlined, size: 42)),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Container(width: 44, height: 44, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
        ),
      ),
    );
  }
}
