import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../preferences/preferences_service.dart';

enum SevaBadge {
  bhaktiSadhaka('Bhakti Sadhaka', '🪔', 'Starting devotee on the path of sacred service', 0),
  sangeetaSeva('Sangeeta Seva Karta', '🎵', 'Contributed songs & sacred hymns to the community', 50),
  shlokaPunya('Punya Karta', '✨', 'Active devotion, prayers, and song requests', 200),
  sevaRatna('Seva Ratna Mahapurusha', '👑', 'Pinnacle of devotion and seva contributions', 500);

  final String title;
  final String icon;
  final String description;
  final int minTokensEarned;

  const SevaBadge(this.title, this.icon, this.description, this.minTokensEarned);
}

class SevaTransaction {
  final String id;
  final int amount;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCredit;

  const SevaTransaction({
    required this.id,
    required this.amount,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isCredit,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'isCredit': isCredit,
  };

  factory SevaTransaction.fromJson(Map<String, dynamic> json) => SevaTransaction(
    id: json['id'] as String? ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
        : DateTime.now(),
    isCredit: json['isCredit'] as bool? ?? true,
  );
}

class SevaTokenService extends ChangeNotifier {
  static const String _keyTokens = 'bhakti_seva_tokens_balance';
  static const String _keyTotalEarned = 'bhakti_seva_tokens_total_earned';
  static const String _keyHistory = 'bhakti_seva_tokens_history';
  static const String _keyAdFreeExpiry = 'bhakti_seva_ad_free_expiry';

  final PreferencesService? prefsService;
  int _tokenBalance = 0;
  int _totalTokensEarned = 0;
  List<SevaTransaction> _history = [];
  DateTime? _adFreeExpiryDate;

  SevaTokenService([this.prefsService]) {
    _loadState();
  }

  int get tokenBalance => _tokenBalance;
  int get totalTokensEarned => _totalTokensEarned;
  List<SevaTransaction> get history => List.unmodifiable(_history);
  DateTime? get adFreeExpiryDate => _adFreeExpiryDate;
  bool get hasActiveAdFreePass =>
      _adFreeExpiryDate != null && _adFreeExpiryDate!.isAfter(DateTime.now());

  List<SevaBadge> get unlockedBadges {
    return SevaBadge.values
        .where((badge) => _totalTokensEarned >= badge.minTokensEarned)
        .toList();
  }

  SevaBadge get currentBadge {
    final unlocked = unlockedBadges;
    return unlocked.isNotEmpty ? unlocked.last : SevaBadge.bhaktiSadhaka;
  }

  String get devoteePasskey =>
      prefsService?.getDevoteePasskey() ?? 'BHAKTI-7000-DEVOTEE';

  String _getEffectiveUserId() {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null && authUser.uid.isNotEmpty) {
        return authUser.uid;
      }
    } catch (_) {}
    return prefsService?.getDevoteeUserId() ?? 'devotee_local';
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _tokenBalance = prefs.getInt(_keyTokens) ?? 5; // Starter 5 Seva blessing tokens
      _totalTokensEarned = prefs.getInt(_keyTotalEarned) ?? _tokenBalance;

      final historyJson = prefs.getString(_keyHistory);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _history = decoded.map((e) => SevaTransaction.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Welcome bonus transaction
        _history = [
          SevaTransaction(
            id: 'welcome_init',
            amount: 5,
            title: 'Sacred Prarambha Blessing 🪔',
            description: 'Welcome Seva tokens for joining the Bhakti platform',
            timestamp: DateTime.now(),
            isCredit: true,
          ),
        ];
      }

      final expiryStr = prefs.getString(_keyAdFreeExpiry);
      if (expiryStr != null) {
        _adFreeExpiryDate = DateTime.tryParse(expiryStr);
      }

      notifyListeners();

      // Cloud Restore & Sync (Preserves points across app uninstalls & multi-device)
      _syncFromCloud();
    } catch (e) {
      debugPrint('Error loading SevaTokenService state: $e');
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final fs = _firestore;
      if (fs == null) return;

      final passkey = devoteePasskey;
      final doc = await fs.collection('passkeys').doc(passkey).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cloudBalance = (data['tokenBalance'] as num?)?.toInt() ?? 0;
        final cloudTotalEarned = (data['totalTokensEarned'] as num?)?.toInt() ?? 0;

        // If cloud holds restored data after reinstall
        if (cloudTotalEarned > _totalTokensEarned || cloudBalance > _tokenBalance) {
          _tokenBalance = cloudBalance;
          _totalTokensEarned = cloudTotalEarned;

          if (data['adFreeExpiryDate'] != null) {
            final cloudExpiry = DateTime.tryParse(data['adFreeExpiryDate'] as String);
            if (cloudExpiry != null && (_adFreeExpiryDate == null || cloudExpiry.isAfter(_adFreeExpiryDate!))) {
              _adFreeExpiryDate = cloudExpiry;
            }
          }

          notifyListeners();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_keyTokens, _tokenBalance);
          await prefs.setInt(_keyTotalEarned, _totalTokensEarned);
          if (_adFreeExpiryDate != null) {
            await prefs.setString(_keyAdFreeExpiry, _adFreeExpiryDate!.toIso8601String());
          }
          debugPrint('☁️ [SevaTokenService] Restored Seva Karma Points from Passkey Cloud: $_tokenBalance 🪙');
        }
      }
    } catch (e) {
      debugPrint('Notice syncing Seva wallet from passkey cloud: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTokens, _tokenBalance);
      await prefs.setInt(_keyTotalEarned, _totalTokensEarned);
      final historyJson = jsonEncode(_history.map((e) => e.toJson()).toList());
      await prefs.setString(_keyHistory, historyJson);

      if (_adFreeExpiryDate != null) {
        await prefs.setString(_keyAdFreeExpiry, _adFreeExpiryDate!.toIso8601String());
      } else {
        await prefs.remove(_keyAdFreeExpiry);
      }

      // Sync to Cloud Firestore under both user ID and Sacred Passkey for 100% anonymous recovery
      final fs = _firestore;
      if (fs != null) {
        final passkey = devoteePasskey;
        final userId = _getEffectiveUserId();

        final payload = {
          'passkey': passkey,
          'tokenBalance': _tokenBalance,
          'totalTokensEarned': _totalTokensEarned,
          'adFreeExpiryDate': _adFreeExpiryDate?.toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
        };

        // Write to both paths for seamless recovery
        await Future.wait([
          fs.collection('passkeys').doc(passkey).set(payload, SetOptions(merge: true)),
          fs.collection('users').doc(userId).collection('wallet').doc('seva_karma').set(payload, SetOptions(merge: true)),
        ]);
      }
    } catch (e) {
      debugPrint('Error saving SevaTokenService state: $e');
    }
  }

  /// Restores points, badges, and VIP passes using a Sacred Devotee Passkey
  Future<bool> restoreFromPasskey(String rawInput) async {
    final cleanPasskey = rawInput.trim().toUpperCase();
    if (cleanPasskey.isEmpty) return false;

    try {
      final fs = _firestore;
      if (fs == null) return false;

      final doc = await fs.collection('passkeys').doc(cleanPasskey).get();
      if (!doc.exists || doc.data() == null) {
        return false;
      }

      final data = doc.data()!;
      _tokenBalance = (data['tokenBalance'] as num?)?.toInt() ?? _tokenBalance;
      _totalTokensEarned = (data['totalTokensEarned'] as num?)?.toInt() ?? _totalTokensEarned;

      if (data['adFreeExpiryDate'] != null) {
        final expiry = DateTime.tryParse(data['adFreeExpiryDate'] as String);
        if (expiry != null) {
          _adFreeExpiryDate = expiry;
        }
      }

      // Update local active passkey
      if (prefsService != null) {
        await prefsService!.setDevoteePasskey(cleanPasskey);
      }

      final tx = SevaTransaction(
        id: 'restore_${DateTime.now().millisecondsSinceEpoch}',
        amount: 0,
        title: 'Passkey Restored ✨',
        description: 'Restored wallet from Sacred Passkey: $cleanPasskey',
        timestamp: DateTime.now(),
        isCredit: true,
      );
      _history.insert(0, tx);

      notifyListeners();
      await _saveState();
      debugPrint('✨ [SevaTokenService] Restored passkey $cleanPasskey with $_tokenBalance tokens');
      return true;
    } catch (e) {
      debugPrint('Error restoring from passkey: $e');
      return false;
    }
  }

  /// Award Seva tokens to the devotee (e.g. song upload +50, request +20, shloka +5)
  Future<void> awardTokens({
    required int amount,
    required String title,
    required String description,
  }) async {
    if (amount <= 0) return;

    _tokenBalance += amount;
    _totalTokensEarned += amount;

    final tx = SevaTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      isCredit: true,
    );

    _history.insert(0, tx);
    if (_history.length > 50) _history = _history.sublist(0, 50);

    notifyListeners();
    await _saveState();
    debugPrint('🪙 [SevaTokenService] Awarded +$amount tokens for "$title". New Balance: $_tokenBalance');
  }

  /// Redeem tokens for Ad-Free devotional listening pass
  Future<bool> redeemAdFreePass({required int days, required int costTokens}) async {
    if (_tokenBalance < costTokens) {
      return false;
    }

    _tokenBalance -= costTokens;

    final now = DateTime.now();
    final baseDate = (_adFreeExpiryDate != null && _adFreeExpiryDate!.isAfter(now))
        ? _adFreeExpiryDate!
        : now;
    _adFreeExpiryDate = baseDate.add(Duration(days: days));

    final tx = SevaTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      amount: costTokens,
      title: 'Redeemed $days-Day Ad-Free Pass 🚫',
      description: 'Activated divine uninterrupted listening until ${_formatDate(_adFreeExpiryDate!)}',
      timestamp: DateTime.now(),
      isCredit: false,
    );

    _history.insert(0, tx);
    notifyListeners();
    await _saveState();
    return true;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
