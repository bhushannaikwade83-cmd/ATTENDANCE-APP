import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/error_handler.dart';

class AttendanceReportsScreen extends StatefulWidget {
  static const routeName = '/attendance-reports';
  const AttendanceReportsScreen({super.key});

  @override
  State<AttendanceReportsScreen> createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  String? _instituteId;
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _selectedEndDate = DateTime.now();
  String? _selectedSubject;
  bool _isLoading = false;
  Map<String, dynamic> _reportData = {};

  final List<String> _subjects = [
    'English 30',
    'English 40',
    'Hindi 30',
    'Hindi 40',
    'Marathi 30',
    'Marathi 40',
    'All Subjects',
  ];

  @override
  void initState() {
    super.initState();
    _loadInstituteId();
  }

  Future<void> _loadInstituteId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final institutesSnapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .limit(100)
          .get();
      
      for (var instituteDoc in institutesSnapshot.docs) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('institutes')
              .doc(instituteDoc.id)
              .collection('users')
              .doc(uid)
              .get();
          
          if (doc.exists) {
            final userData = doc.data();
            setState(() {
              _instituteId = userData?['instituteId'] as String? ?? instituteDoc.id;
            });
            _generateReport();
            return;
          }
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      if (mounted) {
        final errorResult = ErrorHandler.formatErrorForUI(e, context: 'loadInstituteId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorResult['message']),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    if (_instituteId == null) return;

    setState(() => _isLoading = true);

    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(_selectedStartDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_selectedEndDate);

      Query query = FirebaseFirestore.instance
          .collection('institutes')
          .doc(_instituteId)
          .collection('attendance');

      // Filter by date range
      query = query.where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr);

      // Filter by subject if selected
      if (_selectedSubject != null && _selectedSubject != 'All Subjects') {
        query = query.where('subject', isEqualTo: _selectedSubject);
      }

      final snapshot = await query.get();

      // Process data
      Map<String, int> dailyPresent = {};
      Map<String, int> dailyTotal = {};
      Map<String, Set<String>> studentsByDate = {};
      Map<String, int> studentAttendanceCount = {};
      int totalPresent = 0;
      int totalRecords = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = data['date'] as String? ?? '';
        final status = data['status'] as String? ?? '';
        final rollNumber = data['rollNumber'] as String? ?? '';

        if (date.isNotEmpty) {
          dailyTotal[date] = (dailyTotal[date] ?? 0) + 1;
          if (status == 'present') {
            dailyPresent[date] = (dailyPresent[date] ?? 0) + 1;
            totalPresent++;
            
            if (!studentsByDate.containsKey(date)) {
              studentsByDate[date] = <String>{};
            }
            studentsByDate[date]!.add(rollNumber);
            
            studentAttendanceCount[rollNumber] = (studentAttendanceCount[rollNumber] ?? 0) + 1;
          }
          totalRecords++;
        }
      }

      setState(() {
        _reportData = {
          'dailyPresent': dailyPresent,
          'dailyTotal': dailyTotal,
          'studentsByDate': studentsByDate,
          'studentAttendanceCount': studentAttendanceCount,
          'totalPresent': totalPresent,
          'totalRecords': totalRecords,
          'averageAttendance': totalRecords > 0 ? (totalPresent / totalRecords * 100) : 0.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorResult = ErrorHandler.formatErrorForUI(e, context: 'generateReport', appType: 'admin');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorResult['message']),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Range Selection
            _buildDateRangeSelector(),
            const SizedBox(height: 20),

            // Subject Filter
            _buildSubjectFilter(),
            const SizedBox(height: 20),

            // Generate Report Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateReport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics),
              label: Text(_isLoading ? 'Generating...' : 'Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards
            if (_reportData.isNotEmpty) ...[
              _buildSummaryCards(),
              const SizedBox(height: 24),

              // Daily Attendance Chart
              _buildDailyAttendanceChart(),
              const SizedBox(height: 24),

              // Top Students
              _buildTopStudents(),
            ],

            if (_reportData.isEmpty && !_isLoading)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.analytics_outlined, size: 64, color: AppTheme.textGray),
                    const SizedBox(height: 16),
                    Text(
                      'No data available',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select date range and generate report',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date Range',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedStartDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedStartDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_selectedStartDate),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedEndDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedEndDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_selectedEndDate),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Filter',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: const InputDecoration(
              labelText: 'Subject',
              prefixIcon: Icon(Icons.book_outlined),
            ),
            items: _subjects.map((subject) {
              return DropdownMenuItem(
                value: subject,
                child: Text(subject),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedSubject = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalPresent = _reportData['totalPresent'] as int? ?? 0;
    final totalRecords = _reportData['totalRecords'] as int? ?? 0;
    final averageAttendance = _reportData['averageAttendance'] as double? ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Present',
            value: '$totalPresent',
            color: AppTheme.accentGreen,
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Records',
            value: '$totalRecords',
            color: AppTheme.primaryGreen,
            icon: Icons.people,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Avg Attendance',
            value: '${averageAttendance.toStringAsFixed(1)}%',
            color: AppTheme.accentOrange,
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyAttendanceChart() {
    final dailyPresent = _reportData['dailyPresent'] as Map<String, int>? ?? {};
    final dailyTotal = _reportData['dailyTotal'] as Map<String, int>? ?? {};

    if (dailyPresent.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = dailyPresent.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Attendance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...sortedDates.map((date) {
            final present = dailyPresent[date] ?? 0;
            final total = dailyTotal[date] ?? 1;
            final percentage = (present / total * 100);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(DateTime.parse(date)),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$present / $total (${percentage.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 80 ? AppTheme.accentGreen :
                        percentage >= 60 ? AppTheme.accentOrange :
                        AppTheme.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopStudents() {
    final studentAttendanceCount = _reportData['studentAttendanceCount'] as Map<String, int>? ?? {};

    if (studentAttendanceCount.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedStudents = studentAttendanceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topStudents = sortedStudents.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Students by Attendance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...topStudents.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: index < 3
                          ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? AppTheme.primaryGreen : AppTheme.textGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Roll ${student.key}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${student.value} days',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
