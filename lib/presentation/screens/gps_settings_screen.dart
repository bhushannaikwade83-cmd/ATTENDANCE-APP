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
  bool _isSuperAdmin = false;
  bool _isCheckingRole = true;
  String? _instituteId; // Store user's institute ID
  bool _isGpsLocked = false;
  String? _lockedBy;
  final _formKey = GlobalKey<FormState>();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: "100"); // Default 100m
  bool _isLoading = false;

  DocumentReference<Map<String, dynamic>>? get _adminGpsRef {
    if (_instituteId == null || _currentUser == null) return null;
    return FirebaseFirestore.instance
        .collection('institutes')
        .doc(_instituteId)
        .collection('gps_settings')
        .doc(_currentUser.uid);
  }

  @override
  void initState() {
    super.initState();
    _loadUserInstituteId();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
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
      await _checkSuperAdmin(uid);
      
            // 1) Try top-level users profile
      final topDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final topData = topDoc.data();
      final topInstituteId = (topData?['instituteId'] ?? '').toString().trim();
      if (topInstituteId.isNotEmpty) {
        _instituteId = topInstituteId;
        final role = (topData?['role'] ?? '').toString();
        if (kDebugMode) {
          debugPrint('? User found in top-level users, role: $role');
        }
        setState(() {
          _isAdmin = role == 'admin';
          _isCheckingRole = false;
        });
        if ((_isAdmin || _isSuperAdmin) && _instituteId != null) {
          _loadCurrentSettings();
        }
        return;
      }

      // 2) Try collectionGroup users (institute users subcollection)
      try {
        final query = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          _instituteId = (data['instituteId'] ?? '').toString().trim();
          final role = (data['role'] ?? '').toString();
          if (kDebugMode) {
            debugPrint('? User found in institute users, role: $role');
          }
          setState(() {
            _isAdmin = role == 'admin';
            _isCheckingRole = false;
          });
          if ((_isAdmin || _isSuperAdmin) && _instituteId != null) {
            _loadCurrentSettings();
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error querying collectionGroup users: $e');
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
                _instituteId = (userData['instituteId'] as String?) ?? instituteDoc.id;
                final role = userData['role'] as String? ?? '';
                
                if (kDebugMode) debugPrint('✅ User found in institute ${instituteDoc.id}, role: $role');
                
                setState(() {
                  _isAdmin = role == 'admin';
                  _isCheckingRole = false;
                });
                
                if ((_isAdmin || _isSuperAdmin) && _instituteId != null) {
                  _loadCurrentSettings();
                } else if (!_isAdmin && !_isSuperAdmin) {
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
          
          if (_isAdmin || _isSuperAdmin) {
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

  Future<void> _checkSuperAdmin(String uid) async {
    try {
      final coderDoc =
          await FirebaseFirestore.instance.collection('coders').doc(uid).get();
      if (!coderDoc.exists) return;
      final data = coderDoc.data();
      final role = (data?['role'] ?? '').toString();
      final isSuper = data?['isSuperAdmin'] == true ||
          role == 'super_admin' ||
          role == 'superadmin';
      _isSuperAdmin = isSuper;
      if (kDebugMode && _isSuperAdmin) {
        debugPrint('✅ Super admin authorization detected');
      }
    } catch (_) {}
  }

  // 1. Load existing settings from Firestore
  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc;
      
      // Primary source: admin-specific GPS config.
      if (_instituteId != null && _currentUser != null) {
        doc = await FirebaseFirestore.instance
            .collection('institutes')
            .doc(_instituteId)
            .collection('gps_settings')
            .doc(_currentUser.uid)
            .get();
        if (!doc.exists) {
          // Backward compatibility: old shared config.
          doc = await FirebaseFirestore.instance
              .collection('institutes')
              .doc(_instituteId)
              .collection('gps_settings')
              .doc('config')
              .get();
        }
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
          _isGpsLocked = data['isLocked'] == true;
          _lockedBy = data['lockedBy']?.toString();
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
    if (_isGpsLocked && !_isSuperAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "GPS is finalized and locked. Only Super Admin can modify location/radius.",
            ),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Save to institute config used by attendance checks.
      if (_currentUser == null) {
        throw 'User not authenticated';
      }
      
      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(_instituteId)
          .collection('gps_settings')
          .doc(_currentUser.uid)
          .set({
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lngController.text),
        'radius': double.parse(_radiusController.text),
        'updatedAt': FieldValue.serverTimestamp(),
        'instituteId': _instituteId,
        'adminId': _currentUser.uid,
        'docType': 'admin_gps',
        'isLocked': _isGpsLocked,
        'lockedBy': _lockedBy,
        'updatedBySuperAdmin': _isSuperAdmin,
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

  Future<void> _setGpsLock(bool lock) async {
    if (_instituteId == null || _currentUser == null) return;
    if (!lock && !_isSuperAdmin) return;
    if (lock && !(_isAdmin || _isSuperAdmin)) return;

    setState(() => _isLoading = true);
    try {
      final configRef = _adminGpsRef;
      if (configRef == null) return;

      if (lock) {
        final existing = await configRef.get();
        if (!existing.exists) {
          throw 'Save GPS coordinates first, then lock.';
        }
      }

      await configRef.set({
        'isLocked': lock,
        'lockedBy': lock ? _currentUser.uid : null,
        'lockUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isGpsLocked = lock;
        _lockedBy = lock ? _currentUser.uid : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lock update failed: $e'),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
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

    if (!_isAdmin && !_isSuperAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        appBar: AppBar(
          title: const Text("GPS Geofence Settings"),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Access denied. Only institute admins or super admins can update GPS settings.",
              textAlign: TextAlign.center,
            ),
          ),
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
              if (_isGpsLocked)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isSuperAdmin
                              ? 'GPS config is locked. You can unlock as Super Admin.'
                              : 'GPS config is finalized and locked. Contact Super Admin to change location/radius.',
                        ),
                      ),
                    ],
                  ),
                ),
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
                        "Set institute attendance zone and radius. Once finalized, this can only be changed by Super Admin authorization.",
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
                      enabled: !(_isGpsLocked && !_isSuperAdmin),
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
                      enabled: !(_isGpsLocked && !_isSuperAdmin),
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
                  onPressed: _isLoading || (_isGpsLocked && !_isSuperAdmin)
                      ? null
                      : _getCurrentLocation,
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
                enabled: !(_isGpsLocked && !_isSuperAdmin),
                decoration: const InputDecoration(
                  labelText: "Radius in Meters",
                  prefixIcon: Icon(Icons.radar_outlined),
                  helperText: "Recommended: 50 - 100 meters",
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 40),

              if ((!_isGpsLocked && (_isAdmin || _isSuperAdmin)) ||
                  (_isGpsLocked && _isSuperAdmin))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _setGpsLock(!_isGpsLocked),
                    icon: Icon(_isGpsLocked ? Icons.lock_open : Icons.lock),
                    label: Text(
                      _isGpsLocked
                          ? 'Unlock GPS (Super Admin)'
                          : 'Finalize and Lock GPS',
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || (_isGpsLocked && !_isSuperAdmin)
                      ? null
                      : _saveSettings,
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

