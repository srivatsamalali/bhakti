class LanguageModel {
  final String code;
  final String nativeName;
  final String englishName;
  final String scriptSymbol;

  const LanguageModel({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.scriptSymbol,
  });

  static const List<LanguageModel> supported = [
    LanguageModel(
      code: 'kn',
      nativeName: 'ಕನ್ನಡ',
      englishName: 'Kannada',
      scriptSymbol: 'ಕ',
    ),
    LanguageModel(
      code: 'en',
      nativeName: 'English',
      englishName: 'English',
      scriptSymbol: 'A',
    ),
    LanguageModel(
      code: 'hi',
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
      scriptSymbol: 'अ',
    ),
    LanguageModel(
      code: 'ta',
      nativeName: 'தமிழ்',
      englishName: 'Tamil',
      scriptSymbol: 'அ',
    ),
    LanguageModel(
      code: 'ml',
      nativeName: 'മലയാളം',
      englishName: 'Malayalam',
      scriptSymbol: 'അ',
    ),
  ];

  static LanguageModel fromCode(String code) {
    return supported.firstWhere(
      (l) => l.code == code,
      orElse: () => supported[0], // Kannada default
    );
  }
}
