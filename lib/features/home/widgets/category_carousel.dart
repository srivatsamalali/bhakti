import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/category_model.dart';
import '../../../repositories/category_repository.dart';
import '../../../services/preferences/preferences_service.dart';

class CategoryCarousel extends StatelessWidget {
  final Function(CategoryModel category) onCategorySelected;

  const CategoryCarousel({super.key, required this.onCategorySelected});

  static const List<LinearGradient> _categoryGradients = [
    AppColors.heroMaroonGradient,
    AppColors.sacredAmberGradient,
    AppColors.vrindavanEmeraldGradient,
    AppColors.royalTempleGradient,
    AppColors.gangaAzureGradient,
    AppColors.lotusPinkGradient,
  ];

  IconData _getCategoryIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'temple':
        return Icons.temple_hindu;
      case 'om':
        return Icons.auto_awesome;
      case 'lotus':
        return Icons.spa;
      case 'bell':
        return Icons.notifications_active;
      case 'diya':
      case 'lamp':
        return Icons.wb_incandescent;
      case 'music':
      default:
        return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catRepo = context.watch<CategoryRepository>();
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final categories = catRepo.categories;

    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('browseByCategory'),
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.maroonPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${categories.length} ${context.tr('browseByCategory')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final gradient = _categoryGradients[index % _categoryGradients.length];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: InkWell(
                  onTap: () => onCategorySelected(cat),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 115,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.goldLight.withOpacity(0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.goldLight.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            _getCategoryIcon(cat.icon),
                            color: AppColors.goldLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.getLocalizedName(currentLang),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
