import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../preferences/preferences_service.dart';

enum SevaBadge {
  bhaktiSadhaka('Bhakti Sadhaka', '🪔', 'Starting devotee on the path of sacred service', 0),
  sangeetaSeva('Sangeeta Seva Karta', '🎵', 'Contributed songs & sacred hymns to the community', 50),
  shlokaPunya('Punya Karta', '✨', 'Active devotion, prayers, and song requests', 100),
  sevaRatna('Seva Ratna Mahapurusha', '👑', 'Pinnacle of devotion and seva contributions', 250);

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

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _tokenBalance = prefs.getInt(_keyTokens) ?? 25; // Starter 25 Seva blessing tokens
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
            amount: 25,
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
    } catch (e) {
      debugPrint('Error loading SevaTokenService state: $e');
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
    } catch (e) {
      debugPrint('Error saving SevaTokenService state: $e');
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
