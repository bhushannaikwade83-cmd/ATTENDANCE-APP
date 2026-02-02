import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'institute_registration_screen.dart';

class InstituteSearchScreen extends StatefulWidget {
  static const routeName = '/institute-search';
  const InstituteSearchScreen({super.key});

  @override
  State<InstituteSearchScreen> createState() => _InstituteSearchScreenState();
}

class _InstituteSearchScreenState extends State<InstituteSearchScreen> {
  final _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPredefinedInstitutes();
  }

  // Load all institutes from database
  Future<void> _loadPredefinedInstitutes() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all existing institutes from database
      // Using limit to ensure we can read the collection
      final allInstitutes = await _firestore
          .collection('institutes')
          .limit(100) // Add limit to make query more efficient
          .get();
      _updateSearchResults(allInstitutes);
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading institutes: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading institutes: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _updateSearchResults(QuerySnapshot snapshot) {
    setState(() {
      _searchResults = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'instituteId': data['instituteId'] ?? doc.id,
          'name': data['name'] ?? 'Unknown',
          'location': data['location'] ?? '',
          'city': data['city'] ?? '',
          'state': data['state'] ?? '',
          ...data,
        };
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _searchInstitutes(String query) async {
    if (query.isEmpty) {
      _loadPredefinedInstitutes();
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Try Firestore query first
      final snapshot = await _firestore
          .collection('institutes')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(50)
          .get();

      setState(() {
        _searchResults = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'instituteId': data['instituteId'] ?? doc.id,
            'name': data['name'] ?? 'Unknown',
            'location': data['location'] ?? '',
            'city': data['city'] ?? '',
            'state': data['state'] ?? '',
            ...data,
          };
        }).toList();
        _isSearching = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error searching institutes: $e');
      // Fallback: search in loaded results
      setState(() {
        _searchResults = _searchResults.where((institute) {
          final name = (institute['name'] ?? '').toString().toLowerCase();
          final location = (institute['location'] ?? '').toString().toLowerCase();
          final queryLower = query.toLowerCase();
          return name.contains(queryLower) || location.contains(queryLower);
        }).toList();
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        title: const Text('Find Your Institute'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search institute name or location...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadPredefinedInstitutes();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundOffWhite,
                ),
                onChanged: _searchInstitutes,
              ),
            ),

            // Results List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isSearching
                                    ? 'Searching...'
                                    : 'No institutes found',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try searching with a different keyword',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final institute = _searchResults[index];
                            return _buildInstituteCard(institute);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstituteCard(Map<String, dynamic> institute) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InstituteRegistrationScreen(
                  instituteId: institute['instituteId'] ?? institute['id'],
                  instituteName: institute['name'] ?? 'Unknown',
                  instituteLocation: institute['location'] ?? '',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              institute['name'] ?? 'Unknown Institute',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (institute['instituteCode'] != null && institute['instituteCode'].toString().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Code: ${institute['instituteCode']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              institute['address'] ?? institute['location'] ?? 'Address not specified',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (institute['city'] != null || institute['district'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (institute['city'] != null) ...[
                              Text(
                                institute['city'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                              ),
                            ],
                            if (institute['district'] != null && institute['district'] != institute['city']) ...[
                              if (institute['city'] != null) const Text(', ', style: TextStyle(color: AppTheme.textGray)),
                              Text(
                                institute['district'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                              ),
                            ],
                            if (institute['taluka'] != null) ...[
                              if (institute['district'] != null || institute['city'] != null) 
                                const Text(', ', style: TextStyle(color: AppTheme.textGray)),
                              Text(
                                'Taluka: ${institute['taluka']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textGray,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (institute['state'] != null) ...[
                              Text(
                                '${institute['city'] != null || institute['district'] != null ? ', ' : ''}${institute['state']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (institute['mobileNo'] != null && institute['mobileNo'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppTheme.textGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              institute['mobileNo'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.primaryGreen,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
