import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../services/firebase/firestore_service.dart';

class CategoryRepository extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryRepository(this._firestoreService) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _firestoreService.getCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
