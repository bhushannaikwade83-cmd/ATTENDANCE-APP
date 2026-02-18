import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'institute_details_screen.dart';
import 'super_admin_pin_login_screen.dart';
import '../services/super_admin_pin_auth_service.dart';
import '../services/super_admin_service.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showInstituteForm({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final isEdit = doc != null;
    final data = doc?.data() ?? <String, dynamic>{};

    final idController = TextEditingController(text: (data['instituteId'] ?? doc?.id ?? '').toString());
    final nameController = TextEditingController(text: (data['name'] ?? '').toString());
    final codeController = TextEditingController(text: (data['instituteCode'] ?? '').toString());
    final cityController = TextEditingController(text: (data['city'] ?? '').toString());
    final stateController = TextEditingController(text: (data['state'] ?? '').toString());
    var isActive = (data['isActive'] ?? true) == true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Institute' : 'Create Institute'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      enabled: !isEdit,
                      decoration: const InputDecoration(labelText: 'Institute ID'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Institute Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Institute Code'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (v) => setLocalState(() => isActive = v),
                      title: const Text('Institute Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (nameController.text.trim().isEmpty) {
                        throw Exception('Institute name is required.');
                      }

                      if (isEdit) {
                        await SuperAdminService.updateInstitute(
                          instituteId: doc.id,
                          name: nameController.text,
                          instituteCode: codeController.text,
                          city: cityController.text,
                          state: stateController.text,
                          isActive: isActive,
                        );
                      } else {
                        await SuperAdminService.createInstitute(
                          instituteId: idController.text,
                          name: nameController.text,
                          instituteCode: codeController.text,
                          city: cityController.text,
                          state: stateController.text,
                        );
                      }

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(isEdit ? 'Institute updated' : 'Institute created')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteInstitute(String instituteId, String instituteName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Delete Institute'),
        content: Text(
          'Delete "$instituteName" permanently?\n\nThis will remove institute, users, attendance and linked storage files. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete All')),
        ],
      ),
    );

    if (confirm != true) return;
    await SuperAdminService.hardDeleteInstitute(instituteId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Institute permanently deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Control'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xCCFFFFFF),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.apartment), text: 'Institutes'),
            Tab(icon: Icon(Icons.verified_user), text: 'Approvals'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await SuperAdminPinAuthService.lockSession();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SuperAdminPinLoginScreen(),
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6FBFF), Color(0xFFE6EFFA)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            Column(
              children: [
                _institutesSummary(),
                Expanded(child: _institutesTab()),
              ],
            ),
            Column(
              children: [
                _approvalSummary(),
                Expanded(child: _approvalsTab()),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showInstituteForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add Institute'),
          );
        },
      ),
    );
  }

  Widget _institutesSummary() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SuperAdminService.institutesStream(),
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? [])
            .where((d) => (d.data()['isDeleted'] ?? false) != true)
            .toList();
        final activeCount = docs.where((d) => (d.data()['isActive'] ?? true) == true).length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Expanded(child: _topMetric('Institutes', '${docs.length}', Icons.apartment)),
              const SizedBox(width: 10),
              Expanded(child: _topMetric('Active', '$activeCount', Icons.verified)),
            ],
          ),
        );
      },
    );
  }

  Widget _approvalSummary() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SuperAdminService.pendingApprovalsStream(),
      builder: (context, snapshot) {
        final pendingCount = (snapshot.data?.docs ?? [])
            .where((d) => (d.data()['role'] ?? '').toString() == 'admin')
            .length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Expanded(child: _topMetric('Pending', '$pendingCount', Icons.pending_actions)),
              const SizedBox(width: 10),
              Expanded(child: _topMetric('Processed Today', '-', Icons.task_alt)),
            ],
          ),
        );
      },
    );
  }

  Widget _topMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF114B7A), Color(0xFF1B998B)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x22114B7A), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _institutesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SuperAdminService.institutesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = (snapshot.data?.docs ?? [])
            .where((d) => (d.data()['isDeleted'] ?? false) != true)
            .toList();

        if (docs.isEmpty) {
          return const Center(child: Text('No institutes found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data();
            final name = (data['name'] ?? d.id).toString();
            final code = (data['instituteCode'] ?? data['instituteId'] ?? '').toString();
            final studentCount = (data['studentCount'] ?? 0).toString();
            final adminCount = (data['userCount'] ?? 0).toString();
            final isActive = (data['isActive'] ?? true) == true;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 180 + (index * 20)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 14 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive
                        ? const Color(0xFF0F4C81).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.apartment,
                      color: isActive ? const Color(0xFF0F4C81) : Colors.grey.shade700,
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Code: $code | Students: $studentCount | Admins: $adminCount'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'view') {
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InstituteDetailsScreen(
                              instituteId: d.id,
                              instituteName: name,
                            ),
                          ),
                        );
                      } else if (value == 'edit') {
                        await _showInstituteForm(doc: d);
                      } else if (value == 'delete') {
                        await _confirmDeleteInstitute(d.id, name);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('Open')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InstituteDetailsScreen(
                          instituteId: d.id,
                          instituteName: name,
                        ),
                      ),
                    );
                  },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _approvalsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SuperAdminService.pendingApprovalsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = (snapshot.data?.docs ?? [])
            .where((d) => (d.data()['role'] ?? '').toString() == 'admin')
            .toList();

        if (docs.isEmpty) {
          return const Center(child: Text('No pending approvals'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data();
            final name = (data['name'] ?? 'Unnamed').toString();
            final email = (data['email'] ?? '').toString();
            final instituteName = (data['instituteName'] ?? data['instituteId'] ?? '').toString();
            final instituteId = (data['instituteId'] ?? '').toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(email),
                    const SizedBox(height: 4),
                    Text('Institute: $instituteName'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await SuperAdminService.setRegistrationStatus(
                                  userUid: d.id,
                                  instituteId: instituteId,
                                  approved: false,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Registration rejected')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await SuperAdminService.setRegistrationStatus(
                                  userUid: d.id,
                                  instituteId: instituteId,
                                  approved: true,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Registration approved')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
