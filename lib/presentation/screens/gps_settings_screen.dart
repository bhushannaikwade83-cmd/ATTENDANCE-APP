import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class GpsSettingsScreen extends StatefulWidget {
  static const routeName = '/gps-settings';
  const GpsSettingsScreen({super.key});

  @override
  State<GpsSettingsScreen> createState() => _GpsSettingsScreenState();
}

class _GpsSettingsScreenState extends State<GpsSettingsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;
  bool _isCheckingRole = true;
  String? _instituteId; // Store user's institute ID
  final _formKey = GlobalKey<FormState>();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: "100"); // Default 100m
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInstituteId();
  }

  // Load user's institute ID and check admin role
  Future<void> _loadUserInstituteId() async {
    if (_currentUser == null) {
      setState(() {
        _isCheckingRole = false;
        _isAdmin = false;
      });
      return;
    }

    try {
      final uid = _currentUser.uid;
      if (kDebugMode) debugPrint('Loading institute ID for user: $uid');
      
      // Try to read user document directly from known institute IDs first
      // This avoids permission issues with querying all institutes
      final knownInstituteIds = ['3333', 'dummy01']; // Add more if needed
      
      for (var instituteId in knownInstituteIds) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('institutes')
              .doc(instituteId)
              .collection('users')
              .doc(uid)
              .get();
          
          if (doc.exists) {
            final userData = doc.data();
            if (userData != null) {
              _instituteId = userData['instituteId'] as String?;
              final role = userData['role'] as String? ?? '';
              
              if (kDebugMode) debugPrint('✅ User found in institute $instituteId, role: $role');
              
              setState(() {
                _isAdmin = role == 'admin';
                _isCheckingRole = false;
              });
              
              if (_isAdmin && _instituteId != null) {
                _loadCurrentSettings();
              } else if (!_isAdmin) {
                setState(() {
                  _isCheckingRole = false;
                });
              }
              return;
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error checking institute $instituteId: $e');
          continue;
        }
      }
      
      // If not found in known institutes, try querying all institutes (without where clause to avoid permission issues)
      try {
        if (kDebugMode) debugPrint('User not found in known institutes, trying to query all institutes...');
        final institutesSnapshot = await FirebaseFirestore.instance
            .collection('institutes')
            .limit(50)
            .get();

        if (kDebugMode) debugPrint('Found ${institutesSnapshot.docs.length} institutes to check');

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
              if (userData != null) {
                _instituteId = userData['instituteId'] as String?;
                final role = userData['role'] as String? ?? '';
                
                if (kDebugMode) debugPrint('✅ User found in institute ${instituteDoc.id}, role: $role');
                
                setState(() {
                  _isAdmin = role == 'admin';
                  _isCheckingRole = false;
                });
                
                if (_isAdmin && _instituteId != null) {
                  _loadCurrentSettings();
                } else if (!_isAdmin) {
                  setState(() {
                    _isCheckingRole = false;
                  });
                }
                return;
              }
            }
          } catch (permissionError) {
            if (kDebugMode) debugPrint('Permission error checking institute ${instituteDoc.id}: $permissionError');
            continue;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error querying institutes collection: $e');
      }

      // Fallback to old structure
      try {
        if (kDebugMode) debugPrint('Checking old users collection...');
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        
        if (doc.exists) {
          final userData = doc.data();
          final role = userData?['role'] as String? ?? '';
          if (kDebugMode) debugPrint('User found in old structure, role: $role');
          
          setState(() {
            _isAdmin = role == 'admin';
            _isCheckingRole = false;
          });
          
          if (_isAdmin) {
            _loadCurrentSettings();
          }
        } else {
          if (kDebugMode) debugPrint('User not found in any structure');
          setState(() {
            _isCheckingRole = false;
            _isAdmin = false;
          });
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error checking old structure: $e');
        setState(() {
          _isCheckingRole = false;
          _isAdmin = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking role: $e');
      setState(() {
        _isCheckingRole = false;
        _isAdmin = false;
      });
    }
  }

  // 1. Load existing settings from Firestore
  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc;
      
      // Use admin-specific GPS settings (each admin has their own geo-fencing)
      if (_instituteId != null && _currentUser != null) {
        doc = await FirebaseFirestore.instance
            .collection('institutes')
            .doc(_instituteId)
            .collection('gps_settings')
            .doc(_currentUser!.uid) // Each admin has their own GPS settings
            .get();
      } else {
        // Fallback to old global settings
        doc = await FirebaseFirestore.instance
            .collection('system_settings')
            .doc('gps_config')
            .get();
      }

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _latController.text = data['latitude']?.toString() ?? '';
          _lngController.text = data['longitude']?.toString() ?? '';
          _radiusController.text = data['radius']?.toString() ?? '100';
        }
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Get Current Location (Auto-fill)
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Location fetched successfully!"),
                ],
              ),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Location permission denied"),
                ],
              ),
              backgroundColor: AppTheme.accentRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Save Settings to Firestore
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_instituteId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text("Error: Institute ID not found. Please login again."),
              ],
            ),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Save to admin-specific GPS settings (each admin has their own geo-fencing)
      if (_currentUser == null) {
        throw 'User not authenticated';
      }
      
      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(_instituteId)
          .collection('gps_settings')
          .doc(_currentUser!.uid) // Each admin has their own GPS settings
          .set({
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lngController.text),
        'radius': double.parse(_radiusController.text),
        'updatedAt': FieldValue.serverTimestamp(),
        'instituteId': _instituteId,
        'adminId': _currentUser!.uid, // Store which admin owns this setting
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("GPS Settings Saved!"),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        appBar: AppBar(
          title: const Text("GPS Geofence Settings"),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        title: const Text("GPS Geofence Settings"),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Set your personal attendance zone. Each admin has their own geo-fencing settings. You can only mark attendance within your configured radius.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "School Coordinates",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Latitude",
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Longitude",
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Use Current Location"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    foregroundColor: AppTheme.primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                "Allowed Radius",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Radius in Meters",
                  prefixIcon: Icon(Icons.radar_outlined),
                  helperText: "Recommended: 50 - 100 meters",
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Save Configuration",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
