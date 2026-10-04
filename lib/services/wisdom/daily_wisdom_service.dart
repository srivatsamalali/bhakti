/// Model representing a Sacred Shloka, Vachana or Dasa Sahitya verse with multi-language support.
class SacredWisdomItem {
  final String id;
  final String author;
  final String authorKannada;
  final String title;
  final String deity;
  final String category; // 'Vachana', 'Dasa Sahitya', 'Shloka', 'Mantra'
  final Map<String, String> verseByLang;
  final Map<String, String> meaningByLang;

  const SacredWisdomItem({
    required this.id,
    required this.author,
    required this.authorKannada,
    required this.title,
    required this.deity,
    required this.category,
    required this.verseByLang,
    required this.meaningByLang,
  });

  String getVerse(String langCode) {
    return verseByLang[langCode] ?? verseByLang['kn'] ?? verseByLang['en'] ?? '';
  }

  String getMeaning(String langCode) {
    return meaningByLang[langCode] ?? meaningByLang['kn'] ?? meaningByLang['en'] ?? '';
  }

  String getAuthor(String langCode) {
    if (langCode == 'kn') return authorKannada;
    return author;
  }
}

/// Service providing daily rotating spiritual wisdom with authentic multi-language verses.
class DailyWisdomService {
  static const List<SacredWisdomItem> _wisdomCollection = [
    // 1. Basavanna - Ullavaru Shivalaya
    SacredWisdomItem(
      id: 'basavanna_ullavaru',
      author: 'Jagajyothi Basavanna',
      authorKannada: 'ಜಗಜ್ಯೋತಿ ಬಸವೇಶ್ವರ',
      title: 'ದೇಹವೇ ದೇಗುಲ ವಚನ',
      deity: 'ಕೂಡಲಸಂಗಮದೇವ',
      category: 'Vachana',
      verseByLang: {
        'kn': 'ಉಳ್ಳವರು ಶಿವಾಲಯ ಮಾಡುವರು, ನಾನೇನ ಮಾಡುವೆ ಬಡವನಯ್ಯಾ?\nಎನ್ನ ಕಾಲೇ ಕಂಬ, ದೇಹವೇ ದೇಗುಲ, ಶಿರವೇ ಹೊನ್ನ ಕಳಶವಯ್ಯಾ.\nಕೂಡಲಸಂಗಮದೇವಾ ಕೇಳಯ್ಯಾ, ಸ್ಥಾವರಕ್ಕಳಿವುಂಟು ಜಂಗಮಕ್ಕಳಿವಿಲ್ಲ.',
        'te': 'ఉన్నవారు శివాలయాలు నిర్మిస్తారు, నేనేమి చేయగలను పేదవాడను?\nనా కాళ్లే స్తంభాలు, దేహమే గుడి, శిరస్సే బంగారు కలశం.\nకూడలసంగమదేవా వినవయ్యా, స్థావరం నశించును, జంగమం నిలుచును.',
        'en': 'Uḷḷavaru śivālaya māḍuvaru, nānēna māḍuve baḍavanayyā?\nEnna kālē kamba, dēhavē dēgula, śiravē honna kaḷaśavayyā.\nKūḍalasaṅgamadēvā kēḷayyā, sthāvarakkaḷivuṇṭu jaṅgamakkaḷivilla.',
        'hi': 'धनवान शिवालय बनाते हैं, मैं निर्धन क्या बनाऊं?\nमेरे पैर ही खंभे हैं, शरीर ही पावन मंदिर है, और सिर स्वर्ण कलश है।\nहे कुडलसंगमदेव, स्थिर मंदिर तो नष्ट हो सकते हैं, किंतु चेतन आत्मा शाश्वत है।',
        'ta': 'செல்வந்தர்கள் சிவாலயம் அமைப்பார்கள், ஏழையான நான் என்ன செய்வேன்?\nஎன் கால்களே தூண்கள், உடலே திருக்கோயில், தலையே பொற்கலசம்.\nகூடலசங்கமதேவா! அசையும் உயிர்களுக்கு அழிவில்லை, அசையாததற்கு அழிவுண்டு.',
        'ml': 'ധനവാന്മാർ ശിവക്ഷേത്രം നിർമ്മിക്കും, ദരിദ്രനായ ഞാൻ എന്തു ചെയ്യും?\nഎന്റെ കാലുകൾ തൂണുകൾ, ശരീരം ക്ഷേത്രം, ശിരസ്സ് സ്വർണ്ണകലശം.\nകൂടലസംഗമദേവാ, ചലിക്കുന്ന ആത്മാവിന് നാശമില്ല, ചലിക്കാത്തതിന് നാശമുണ്ട്.',
      },
      meaningByLang: {
        'kn': 'ನಮ್ಮ ದೇಹವೇ ಪರಮಾತ್ಮ ನೆಲೆಸಿರುವ ಪವಿತ್ರ ಮಂದಿರ. ಬಾಹ್ಯ ಆಡಂಬರಕ್ಕಿಂತ ಪರಿಶುದ್ಧ ಮನಸ್ಸಿನ ಆಂತರಿಕ ಭಕ್ತಿಯೇ ಸಾರ್ವಕಾಲಿಕ ಮತ್ತು ಶಾಶ್ವತ.',
        'te': 'మన శరీరమే భగవంతుడు కొలువైన సజీవ ఆలయం. బాహ్య భవనాల కంటే పవిత్రమైన అంతరంగ భక్తే శాశ్వతమైనది.',
        'en': 'The rich build stone temples, but the human body is the true living shrine of God. Physical edifices may fall, but the pure devoted spirit is immortal.',
        'hi': 'मनुष्य का शरीर ही परमात्मा का पावन मंदिर है। बाह्य आडंबर से अधिक आंतरिक भक्ति ही शाश्वत और कल्याणकारी है।',
        'ta': 'மனித உடலே இறைவனின் வாழும் திருக்கோவில். அகத்தூய்மையுடன் கூடிய பக்தியே நிலையானது.',
        'ml': 'നമ്മുടെ ശരീരം തന്നെയാണ് പരമാത്മാവിന്റെ ജീവനുള്ള കോവിൽ. ആത്മാർത്ഥമായ ഭക്തിയാണ് ശാശ്വതം.',
      },
    ),

    // 2. Purandara Dasa - Kallu Sakkare Kolliro
    SacredWisdomItem(
      id: 'purandaradasa_kallu',
      author: 'Purandara Dasa',
      authorKannada: 'ಪುರಂದರ ದಾಸರು',
      title: 'ಕಲ್ಲು ಸಕ್ಕರೆ ಕೊಳ್ಳಿರೋ ಕೀರ್ತನೆ',
      deity: 'ಶ್ರೀಕೃಷ್ಣ • ಪುರಂದರ ವಿಠಲ',
      category: 'Dasa Sahitya',
      verseByLang: {
        'kn': 'ಕಲ್ಲು ಸಕ್ಕರೆ ಕೊಳ್ಳಿರೋ ನೀವೆಲ್ಲರು ಶರಣರು ಕೊಳ್ಳಿರೋ ॥\nಕಲ್ಲು ಸಕ್ಕರೆ ಕೊಂಡರೆ ಮನದೊಳು ಶಾಂತಿ ದೊರಕುವುದು,\nಶ್ರೀಕೃಷ್ಣನೆಂಬ ಕಲ್ಲು ಸಕ್ಕರೆ ಅಮೃತದಂತೆ ಸವಿಯಿಹುದು ॥',
        'te': 'కల్లు చక్కర కొనుక్కోండి మీరెల్లరూ, శరణులు కొనుక్కోండి ॥\nకల్లు చక్కర కొంటే మనసున శాంతి కలుగును,\nశ్రీకృష్ణుడనే కల్లు చక్కర అమృతం వంటిది ॥',
        'en': 'Kallu sakkare koḷḷirō nīvellaru śaraṇaru koḷḷirō ॥\nKallu sakkare koṇḍare manadoḷu śānti dorakuvudu,\nŚrīkr̥ṣṇanemba kallu sakkare amr̥tadante saviyihudu ॥',
        'hi': 'हे भक्तों! भगवान श्रीकृष्ण के पावन नाम की मिश्री ग्रहण करो। यह अमृततुल्य नाम मन को असीम शांति और परम आनंद प्रदान करता है।',
        'ta': 'கற்கண்டு போன்ற ஸ்ரீ கிருஷ்ணரின் திருநாமத்தை ஏற்றிடுங்கள். அது உள்ளத்தில் அமைதியையும் பரமானந்தத்தையும் தரும்.',
        'ml': 'കൽക്കണ്ടം പോലുള്ള ശ്രീകൃഷ്ണ നാമാമൃതം സ്വീകരിക്കൂ. അത് മനസ്സിൽ സമാധാനവും ആനന്ദവും നൽകും.',
      },
      meaningByLang: {
        'kn': 'ಶ್ರೀಕೃಷ್ಣನ ನಾಮಸ್ಮರಣೆ ಅಮೃತದಷ್ಟು ಮಧುರ. ಭಗವನ್ನಾಮ ಜಪದಿಂದ ಮನಸ್ಸಿನ ಸಮಸ್ತ ದುಗುಡಗಳು ದೂರವಾಗಿ ಶಾಂತಿ ಲಭಿಸುತ್ತದೆ.',
        'te': 'భగవన్నామ స్మరణ అమృతం వంటి దివ్య మధురమైనది. హరి నామాన్ని జపించడం వల్ల సమస్త కష్టాలు నశించి పరమ శాంతి లభిస్తుంది.',
        'en': 'Chanting the sacred name of Sri Krishna is sweeter than rock sugar nectar. Devotion dissolves all worries and brings divine tranquility.',
        'hi': 'भगवान का नाम स्मरण अमृत के समान है जो जीवन के समस्त संतापों को मिटाकर शांति देता है।',
        'ta': 'இறைவனின் நாமஸ்மரணம் அமுதத்தை விட இனிமையானது. அது ஆன்மாவிற்கு அமைதியைத் தருகிறது.',
        'ml': 'ഈശ്വരനാമ ജപം അമൃതം പോലെ മധുരതരവും മനസ്സിന് ശാന്തി നൽകുന്നതുമാണ്.',
      },
    ),

    // 3. Basavanna - Dayavillada Dharmavedeuvadayya
    SacredWisdomItem(
      id: 'basavanna_dayavillada',
      author: 'Jagajyothi Basavanna',
      authorKannada: 'ಜಗಜ್ಯೋತಿ ಬಸವೇಶ್ವರ',
      title: 'ದಯವೇ ಧರ್ಮದ ಮೂಲ ವಚನ',
      deity: 'ಕೂಡಲಸಂಗಮದೇವ',
      category: 'Vachana',
      verseByLang: {
        'kn': 'ದಯವಿಲ್ಲದ ಧರ್ಮವದೇವುದಯ್ಯಾ?\nದಯವೇ ಬೇಕು ಸಕಲ ಪ್ರಾಣಿಗಳೆಲ್ಲರಲ್ಲಿಯೂ.\nದಯವೇ ಧರ್ಮದ ಮೂಲವಯ್ಯಾ,\nಕೂಡಲಸಂಗಮದೇವನಂತಲ್ಲದೊಲ್ಲನಯ್ಯಾ.',
        'te': 'దయలేని ధర్మం ఎక్కడిదయ్యా?\nసమస్త ప్రాణుల యెడల దయ ఉండవలెను.\nదయయే ధర్మానికి మూలమయ్యా,\nకూడలసంగమదేవుడు దయలేని వారిని మెచ్చడయ్యా.',
        'en': 'Dayavillada dharmavadēvudayyā?\nDayavē bēku sakala prāṇigaḷellaralliyū.\nDayavē dharmada mūlavayyā,\nKūḍalasaṅgamadēvanantalladollanayyā.',
        'hi': 'दया बिना धर्म कैसा? सभी प्राणियों के प्रति करुणा और दया ही धर्म का मूल है। कुडलसंगमदेव दया से ही प्रसन्न होते हैं।',
        'ta': 'இரக்கம் இல்லாத தர்மம் எது? அனைத்து உயிர்களிடத்தும் இரக்கமே வேண்டும். இரக்கமே தர்மத்தின் மூலமாகும் கூடலசங்கமதேவா.',
        'ml': 'ദയയില്ലാത്ത ധർമ്മം ഏതാണ്? സകല ജീവികളോടും ദയ വേണം. ദയയാണ് ധർമ്മത്തിന്റെ മൂലം കൂടലസംഗമദേവാ.',
      },
      meaningByLang: {
        'kn': 'ಸಕಲ ಜೀವರಾಶಿಗಳಲ್ಲಿ ಕರುಣೆ, ಪ್ರೀತಿ ಮತ್ತು ದಯೆ ತೋರುವುದೇ ಧರ್ಮದ ಮೂಲ ತತ್ವ. ದಯೆಯಿಲ್ಲದ ಯಾವುದೇ ಪೂಜೆ-ಪುನಸ್ಕಾರವೂ ಭಗವಂತನಿಗೆ ಪ್ರಿಯವಾಗದು.',
        'te': 'సకల జీవుల యెడల కరుణ, ప్రేమ మరియు దయ కలిగి ఉండటమే ధర్మ మూలతత్వం. దయలేని పూజలు భగవంతునికి ప్రీతికరమైనవి కావు.',
        'en': 'Compassion toward all living beings is the foundation of true righteousness (Dharma). Without universal kindness, no ritual pleases the Divine.',
        'hi': 'समस्त जीवों के प्रति दया, प्रेम और करुणा ही धर्म का सार है। दयाहीन पूजा ईश्वर को कभी स्वीकार्य नहीं होती।',
        'ta': 'எல்லா உயிர்களிடத்தும் அன்பு காட்டுவதே மெய்யான அறநெறியாகும்.',
        'ml': 'സകല ജീവജാലങ്ങളോടും കാരുണ്യവും സ്നേഹവും പുലർത്തുന്നതാണ് യഥാർത്ഥ ധർമ്മം.',
      },
    ),

    // 4. Purandara Dasa - Dasana Madiko Enna
    SacredWisdomItem(
      id: 'purandaradasa_dasana',
      author: 'Purandara Dasa',
      authorKannada: 'ಪುರಂದರ ದಾಸರು',
      title: 'ದಾಸನ ಮಾಡಿಕೋ ಎನ್ನ ಕೀರ್ತನೆ',
      deity: 'ವೆಂಕಟರಮಣ • ಪುರಂದರ ವಿಠಲ',
      category: 'Dasa Sahitya',
      verseByLang: {
        'kn': 'ದಾಸನ ಮಾಡಿಕೋ ಎನ್ನ ಸ್ವಾಮಿ ಸಾಸಿರ ನಾಮದ ವೆಂಕಟರಮಣ ।\nದಾಸನ ಮಾಡಿಕೋ ಎನ್ನ ॥\nದುರ್ಬುದ್ಧಿಗಳೆಲ್ಲ ನಿರ್ಮೂಲ ಮಾಡಿ ಸದ್ಬುದ್ಧಿ ಪಾಲಿಸೋ ಶ್ರೀಹರಿಯೇ ॥',
        'te': 'దాసుని చేసుకో నన్ను స్వామి వేయి నామాల వేంకటరమణా ।\nదాసుని చేసుకో నన్ను ॥\nదుర్బుద్ధులన్నింటిని నిర్మూలించి సద్బుద్ధిని ప్రసాదించు శ్రీహరీ ॥',
        'en': 'Dāsana māḍikō enna swāmi sāsira nāmada veṅkaṭaramaṇa ।\nDāsana māḍikō enna ॥\nDurbuddhigaḷella nirmūla māḍi sadbuddhi pālisō śrīhariyē ॥',
        'hi': 'हे सहस्रनाम वाले भगवान वेंकटरमण! मुझे अपना दास बना लीजिए। मेरी समस्त दुर्बुद्धि को नष्ट कर मुझे सद्बुद्धि और ज्ञान प्रदान कीजिए।',
        'ta': 'ஆயிரம் நாமங்கள் கொண்ட வேங்கடரமணா! என்னை உமது தாசனாக்கிக் கொள். தீய எண்ணங்களை அழித்து நற்குணத்தை அருள்வாயாக.',
        'ml': 'ആയിരം നാമങ്ങളുള്ള വെങ്കടരമണാ! എന്നെ അങ്ങയുടെ ദാസനാക്കേണമേ. ദുർബുദ്ധികളെല്ലാം മാറ്റി സദ്ബുദ്ധി നൽകേണമേ.',
      },
      meaningByLang: {
        'kn': 'ಅಹಂಕಾರವನ್ನು ತೊರೆದು ಭಗವಂತನಿಗೆ ಶರಣಾಗಿ, ಸನ್ಮಾರ್ಗ ಮತ್ತು ಸದ್ಬುದ್ಧಿಗಾಗಿ ಪ್ರಾರ್ಥಿಸುವುದು ಭಕ್ತಿಯ ಪರಮ ಗುರಿ.',
        'te': 'అహంకారాన్ని విడిచి భగవంతునికి సంపూర్ణంగా శరణాగతి చెందాలి. దుర్గుణాలను పోగొట్టి సద్బుద్ధిని ప్రసాదించమని శ్రీహరిని ప్రార్థించాలి.',
        'en': 'Surrendering ego to the Divine and seeking wisdom and pure intellect is the true essence of spiritual surrender.',
        'hi': 'अहंकार त्यागकर ईश्वर के चरणों में समर्पित होना और सद्बुद्धि की प्रार्थना करना ही सच्ची भक्ति है।',
        'ta': 'ஆணவத்தை விடுத்து இறைவனிடம் சரணடைந்து நற்புத்தியை வேண்டுவதே பக்தியின் மேன்மையாகும்.',
        'ml': 'അഹംഭാവം വെടിഞ്ഞ് ഈശ്വരനിൽ ശരണം പ്രാപിക്കുകയും സദ്ബുദ്ധിക്കായി പ്രാർത്ഥിക്കുകയും ചെയ്യുക.',
      },
    ),

    // 5. Kanakadasa - Kula Kula Kulavendu
    SacredWisdomItem(
      id: 'kanakadasa_kula',
      author: 'Kanakadasa',
      authorKannada: 'ಕನಕದಾಸರು',
      title: 'ಕುಲ ಕುಲವೆಂದು ಹೊಡೆದಾಡದಿರಿ ಕೀರ್ತನೆ',
      deity: 'ಕಾಗಿನೆಲೆಯಾದಿಕೇಶವ',
      category: 'Dasa Sahitya',
      verseByLang: {
        'kn': 'ಕುಲ ಕುಲ ಕುಲವೆಂದು ಹೊಡೆದಾಡದಿರಿ, ನಿಮ್ಮ ಕುಲದ ನೆಲೆಯನೇನಾದರೂ ಬಲ್ಲಿರಾ?\nಆತ್ಮ ಯಾವ ಕುಲ? ಜೀವ ಯಾವ ಕುಲ? ಪಂಚೇಂದ್ರಿಯಗಳ ಕುಲವಾವದಯ್ಯಾ?\nಕಾಗಿನೆಲೆಯಾದಿಕೇಶವನ ಒಲಿದವನೇ ಉತ್ತಮ ಕುಲದವನು.',
        'te': 'కుల కుల కులమని కొట్లాడకండి, మీ కులపు మూలమేమిటో తెలుసా?\nఆత్మకు ఏ కులం? ప్రాణానికి ఏ కులం? పంచేంద్రియాలకు ఏ కులమయ్యా?\nకాగినెలె ఆదికేశవుని కృప పొందినవాడే ఉత్తమ కులస్థుడు.',
        'en': 'Kula kula kulavendu hoḍedāḍadiri, nimma kulada neleyanēnādarū ballirā?\nĀtma yāva kula? Jīva yāva kula? Pañcēndriyagaḷa kulavāvadayyā?\nKāgineleyādikēśavana olidavanē uttama kuladavanu.',
        'hi': 'जाति-पाति के नाम पर व्यर्थ विवाद मत करो। क्या तुम आत्मा और प्राण की कोई जाति जानते हो? जो प्रभु कागिनेले आदिकेशव की कृपा प्राप्त कर लेता है, वही वास्तव में श्रेष्ठ कुल का है।',
        'ta': 'சாதி குலமென்று சண்டையிடாதீர்கள். ஆன்மாவுக்கு ஏது குலம்? இறைவனின் அருள் பெற்றவனே உத்தம குலத்தான்.',
        'ml': 'ജാതിയുടെ പേരിൽ കലഹിക്കരുത്. ആത്മാവിന് എന്ത് ജാതി? കാഗിനെലെ ആദികേശവന്റെ കൃപ ലഭിച്ചവനാണ് ഉത്തമൻ.',
      },
      meaningByLang: {
        'kn': 'ಜಾತಿ-ಕುಲಗಳ ಭೇದಭಾವ ಅಜ್ಞಾನದ ಸಂಕೇತ. ಭಗವಂತನ ಪ್ರೀತಿ ಮತ್ತು ಸದಾಚಾರವೇ ಮಾನವನ ಶ್ರೇಷ್ಠತೆಯ ನಿಜವಾದ ಅಳತೆಗೋಲು.',
        'te': 'కులం పేరుతో విభేదాలు అజ్ఞానం. పరమాత్ముని యందు భక్తి మరియు సదాచారమే మానవుని ఔన్నత్యాన్ని నిర్ణయిస్తాయి.',
        'en': 'Do not fight over caste or lineage. The soul and vital breath have no caste. Whosoever attains the grace of Lord Kaginele Adikeshava is truly noble.',
        'hi': 'जातिवाद अज्ञानता है। परमात्मा की भक्ति और सत्कर्म ही मनुष्य को महान बनाते हैं।',
        'ta': 'மனிதனின் உயர்வுக்கு அவனது நற்குணமும் பக்தியுமே அளவுகோல் ஆகும்.',
        'ml': 'ജാതിഭേദങ്ങൾക്കപ്പുറം സദ്ഗുണങ്ങളും ഈശ്വരഭക്തിയുമാണ് മനുഷ്യന്റെ മഹത്വം.',
      },
    ),

    // 6. Akka Mahadevi - Bettada Melondu Maneya Maadi
    SacredWisdomItem(
      id: 'akkamahadevi_bettada',
      author: 'Akka Mahadevi',
      authorKannada: 'ಅಕ್ಕ ಮಹಾದೇವಿ',
      title: 'ಶಾಂತಿ ಸಮಾಧಾನದ ವಚನ',
      deity: 'ಚೆನ್ನಮಲ್ಲಿಕಾರ್ಜುನ',
      category: 'Vachana',
      verseByLang: {
        'kn': 'ಬೆಟ್ಟದ ಮೇಲೊಂದು ಮನೆಯ ಮಾಡಿ ಮೃಗಂಗಳಿಗಂಜಿದೊಡೆಂತಯ್ಯಾ?\nಸಮುದ್ರದ ತಡಿಯಲೊಂದು ಮನೆಯ ಮಾಡಿ ತೆರೆ ನೊರೆಗಳಿಗಂಜಿದೊಡೆಂತಯ್ಯಾ?\nಸಂತೆಯೊಳಗೆ ಮನೆಯ ಮಾಡಿ ಶಬ್ದಕ್ಕಂಜಿದೊಡೆಂತಯ್ಯಾ?\nಚೆನ್ನಮಲ್ಲಿಕಾರ್ಜುನಾ ಕೇಳಯ್ಯಾ, ಲೋಕದೊಳಗೆ ಹುಟ್ಟಿದ ಬಳಿಕ ಸ್ತುತಿ-ನಿಂದೆಗಳು ಬಂದಡೆ ಮನದಲ್ಲಿ ಕೋಪವ ತಾಳದೆ ಸಮಾಧಾನಿಯಾಗಿರಬೇಕು.',
        'te': 'కొండపై ఇల్లు కట్టి క్రూరమృగాలకు భయపడితే ఎలా?\nసముద్రతీరంలో ఇల్లు కట్టి అలలకు భయపడితే ఎలా?\nసంతలో ఇల్లు కట్టి శబ్దాలకు భయపడితే ఎలా?\nచెన్నమల్లికార్జునా వినవయ్యా, లోకంలో జన్మించిన తరువాత స్తుతి-నిందలను సమభావంతో స్వీకరించి ప్రశాంతంగా ఉండాలి.',
        'en': 'Beṭṭada mēlondu maneya māḍi mr̥gaṅgaḷigañjidoḍentayyā?\nSamudrada taḍiyalondu maneya māḍi tere noregaḷigañjidoḍentayyā?\nSanteyoḷage maneya māḍi śabdakkañjidoḍentayyā?\nChennamallikārjunā kēḷayyā, lōkadoḷage huṭṭida baḷika stuti-nindegaḷu bandaḍe manadalli kōpava tāḷade samādhāniyāgirabēku.',
        'hi': 'पहाड़ पर घर बनाकर जंगली पशुओं से क्या डरना? समुद्र तट पर रहकर लहरों से क्या डरना? हे चेन्नमल्लिकार्जुन, संसार में रहकर स्तुति और निंदा दोनों को समभाव और शांति से स्वीकार करना चाहिए।',
        'ta': 'மலையில் வீடு கட்டி விலங்குகளுக்கு அஞ்சுவதா? உலகத்தில் பிறந்தபின் புகழையும் இகழ்ச்சியையும் சமமாக ஏற்று அமைதியாக வாழ வேண்டும் சென்னமல்லிகார்ஜுனா.',
        'ml': 'മലമുകളിൽ വീടുണ്ടാക്കി മൃഗങ്ങളെ ഭയപ്പെടുന്നതെങ്ങനെ? ലോകത്തിൽ ജീവിക്കുമ്പോൾ സ്തുതിയും നിന്ദയും സമചിത്തതയോടെ സ്വീകരിക്കണം ചെന്നമല്ലികാർജ്ജുനാ.',
      },
      meaningByLang: {
        'kn': 'ಸಂಸಾರದಲ್ಲಿ ಜೀವಿಸುವಾಗ ಬರುವ ಕಷ್ಟ-ಸುಖ, ಹೊಗಳಿಕೆ-ತೆಗಳಿಕೆಗಳನ್ನು ಸಮಚಿತ್ತದಿಂದ ಸ್ವೀಕರಿಸಿ, ಶಾಂತಿಯುತ ಸಮಾಧಾನ ಸ್ಥಿತಿಯಲ್ಲಿ ಭಗವಂತನನ್ನು ಧ್ಯಾನಿಸಬೇಕು.',
        'te': 'సంసారంలో కష్టసుఖాలు, పొగడ్తలు-నిందలను సమచిత్తంతో స్వీకరించి, ప్రశాంత మనస్సుతో భగవంతుని ధ్యానించాలి.',
        'en': 'Living in this world, do not fear praise or blame. Maintain unwavering peace of mind and equanimity in all circumstances, surrendering to the Lord.',
        'hi': 'संसार में सुख-दुःख, निंदा-स्तुति को समान मानकर शांत चित्त से ईश्वर के ध्यान में लीन रहें।',
        'ta': 'வாழ்வின் இன்ப துன்பங்களை சமநிலையுடன் எதிர்கொண்டு இறைவனை தியானியுங்கள்.',
        'ml': 'സുഖദുഃഖങ്ങളെ സമഭാവനയോടെ സ്വീകരിച്ച് മനശ്ശാന്തിയോടെ ഈശ്വരനെ ഭജിക്കുക.',
      },
    ),

    // 7. Sarvajna - Sarvajnanaembavanu
    SacredWisdomItem(
      id: 'sarvajna_vidye',
      author: 'Sarvajna',
      authorKannada: 'ಸರ್ವಜ್ಞ',
      title: 'ವಿನಯ ಮತ್ತು ವಿದ್ಯೆಯ ತ್ರಿಪದಿ',
      deity: 'ಲೋಕಜ್ಞಾನ',
      category: 'Tripadi',
      verseByLang: {
        'kn': 'ಸರ್ವಜ್ಞನೆಂಬವನು ಗರ್ವದಿಂದಾದವನೆ?\nಸರ್ವರೊಳು ಒಂದೊಂದು ನುಡಿಗಲಿತು ವಿದ್ಯೆಯ\nಪರ್ವತವೆ ಆದ ಸರ್ವಜ್ಞ.',
        'te': 'సర్వజ్ఞుడనేవాడు గర్వంతో కాలేదు,\nఅందరిలోనూ ఒక్కొక్క మంచి మాటను నేర్చుకొని విద్యకు\nపర్వతమయ్యాడు సర్వజ్ఞుడు.',
        'en': 'Sarvajnanembavanu garvadindādavane?\nSarvaroḷu ondondu nuḍigalitu vidyeya\nparvatave āda Sarvajna.',
        'hi': 'सर्वज्ञ कोई अहंकार से नहीं बनता। उसने हर किसी से एक-एक ज्ञान की बात सीखी और ज्ञान का विशाल पर्वत बन गया।',
        'ta': 'அனைத்தும் அறிந்தவன் ஆணவத்தால் ஆவதில்லை. எல்லோரிடமிருந்தும் ஒரு நன்மொழியை கற்று அறிவின் சிகரமானான் சர்வக்ஞன்.',
        'ml': 'എല്ലാം അറിയുന്നവൻ അഹങ്കാരം കൊണ്ടല്ല ഉണ്ടായത്. എല്ലാവരിൽ നിന്നും ഓരോ നല്ല വാക്ക് പഠിച്ച് ജ്ഞാനത്തിന്റെ പർവ്വതമായവനാണ് സർവ്വജ്ഞൻ.',
      },
      meaningByLang: {
        'kn': 'ವಿನಮ್ರತೆಯಿಂದ ಪ್ರತಿಯೊಬ್ಬರಿಂದಲೂ ಒಂದೊಂದು ಸದ್ಗುಣ ಮತ್ತು ಜ್ಞಾನವನ್ನು ಕಲಿಯುವುದರಿಂದಲೇ ಪರಿಪೂರ್ಣ ಜ್ಞಾನಿಯಾಗಲು ಸಾಧ್ಯ.',
        'te': 'వినమ్రతతో ప్రతి ఒక్కరి వద్ద నుండి సద్గుణాలు, జ్ఞానాన్ని నేర్చుకోవడం ద్వారానే పరిపూర్ణ జ్ఞానం లభిస్తుంది.',
        'en': 'True wisdom comes not from arrogance, but from the humble willingness to learn every day from everyone we encounter.',
        'hi': 'सच्चा ज्ञान अहंकार से नहीं, अपितु विनम्रतापूर्वक सभी से कुछ न कुछ सीखने की भावना से प्राप्त होता है।',
        'ta': 'பணிவோடு அனைவரிடமிருந்தும் நற்பண்புகளைக் கற்றுக்கொள்வதே மெய்யறிவுக்கு வழிவகுக்கும்.',
        'ml': 'വിനയത്തോടെ എല്ലാവരിൽ നിന്നും അറിവ് നേടുന്നതിലൂടെ മാത്രമേ യഥാർത്ഥ ജ്ഞാനിയാകാൻ കഴിയൂ.',
      },
    ),

    // 8. Basavanna - Kayakave Kailasa
    SacredWisdomItem(
      id: 'basavanna_kayaka',
      author: 'Jagajyothi Basavanna',
      authorKannada: 'ಜಗಜ್ಯೋತಿ ಬಸವೇಶ್ವರ',
      title: 'ಕಾಯಕವೇ ಕೈಲಾಸ ವಚನ',
      deity: 'ಕೂಡಲಸಂಗಮದೇವ',
      category: 'Vachana',
      verseByLang: {
        'kn': 'ಕಾಯಕವೇ ಕೈಲಾಸ, ಸತ್ಯಶುದ್ಧ ಕಾಯಕದಲ್ಲಿಯೇ ಮೋಕ್ಷ.\nಗುರುದರ್ಶನವಾದರೂ ಕಾಯಕ ಬಿಡಲಾಗದು,\nಲಿಂಗಪೂಜೆಯಾದರೂ ಕಾಯಕದಲ್ಲಿಯೇ ಅಡಗಿದೆ ಕೂಡಲಸಂಗಮದೇವಾ.',
        'te': 'కాయకమే కైలాసం, సత్యశుద్ధమైన కాయకంలోనే మోక్షం.\nగురుదర్శనమైనా కాయకం మానరాదు,\nలింగపూజయైనా కాయకంలోనే ఇమిడి ఉంది కూడలసంగమదేవా.',
        'en': 'Kāyakavē kailāsa, satyaśuddha kāyakadalliyē mōkṣa.\nGurudarśanavādarū kāyaka biḍalāgadu,\nliṅgapūjeyādarū kāyakadalliyē aḍagide Kūḍalasaṅgamadēvā.',
        'hi': 'कर्म ही पूजा और कैलास है। सत्यनिष्ठ निष्काम कर्म में ही मुक्ति है। अपने कर्तव्य का निष्ठापूर्वक पालन करना ही ईश्वर की सर्वोत्तम आराधना है।',
        'ta': 'செயலே தெய்வம், உழைப்பே கைலாசம். தூய்மையான கடமையே மோட்சத்திற்கு வழிவகுக்கும் கூடலசங்கமதேவா.',
        'ml': 'കർമ്മമാണ് കൈലാസം. സത്യസന്ധമായ കർത്തവ്യ നിർവ്വഹണത്തിലാണ് മോക്ഷം കൂടലസംഗമദേവാ.',
      },
      meaningByLang: {
        'kn': 'ಪ್ರಾಮಾಣಿಕ, ನಿಷ್ಠಾವಂತ ಕಾಯಕವೇ ಭಗವಂತನ ಸಾಕ್ಷಾತ್ಕಾರಕ್ಕೆ ಶ್ರೇಷ್ಠ ಮಾರ್ಗ. ಕರ್ತವ್ಯ ನಿಷ್ಠೆಯೇ ಪರಮ ಪೂಜೆ.',
        'te': 'ప్రామాణిక, నిష్కామ కర్మయే భగవంతుని పూజ. కర్తవ్య నిష్టయే పరమ సాధనం.',
        'en': 'Work is Worship. Dedicated, selfless duty performed with truthful integrity is the highest form of spiritual attainment.',
        'hi': 'सत्यनिष्ठ कर्म ही ईश्वर की सर्वोच्च भक्ति है। कर्म के प्रति समर्पण ही कल्याण का मार्ग है।',
        'ta': 'நேர்மையான உழைப்பே இறைவனுக்குச் செய்யும் மிகச் சிறந்த பூசையாகும்.',
        'ml': 'ആത്മാർത്ഥമായ കർമ്മം തന്നെയാണ് ഭഗവത് സേവ.',
      },
    ),

    // 9. Allama Prabhu - Tanu Karagadavaralli
    SacredWisdomItem(
      id: 'allama_tanukaragada',
      author: 'Allama Prabhu',
      authorKannada: 'ಅಲ್ಲಮ ಪ್ರಭು',
      title: 'ಭಾವಶುದ್ಧಿಯ ವಚನ',
      deity: 'ಗುಹೇಶ್ವರ',
      category: 'Vachana',
      verseByLang: {
        'kn': 'ತನು ಕರಗದವರಲ್ಲಿ ಮಜ್ಜನವೇಕೆ?\nಮನ ಕರಗದವರಲ್ಲಿ ಪೂಜೆಯೇಕೆ?\nಭಾವಶುದ್ಧವಿಲ್ಲದ ಭಕ್ತಿಯೇಕೆ ಗುಹೇಶ್ವರಾ?\nಅಂತರಂಗದ ಶುದ್ಧಿಯಿಲ್ಲದ ಪೂಜೆ ವ್ಯರ್ಥವಯ್ಯಾ.',
        'te': 'తనువు కరగని వారికి అభిషేకమెందుకు?\nమనసు కరగని వారికి పూజలెందుకు?\nభావశుద్ధి లేని భక్తి ఎందుకు గుహేశ్వరా?\nఅంతరంగ శుద్ధి లేని పూజ వ్యర్థమయ్యా.',
        'en': 'Tanu karagadavaralli majjanavēke?\nMana karagadavaralli pūjeyēke?\nBhāvaśuddhavillada bhaktiyēke Guhēśvarā?\nAntaraṅgada śuddhiyillada pūje vyarthavayyā.',
        'hi': 'जिसका हृदय भक्ति में न पिघले उसका स्नान कैसा? जिसका मन समर्पित न हो उसका पूजन कैसा? हे गुहेश्वर, आंतरिक भावशुद्धि के बिना बाह्य पूजा व्यर्थ है।',
        'ta': 'உள்ளம் உருகாதவனிடம் பூசை எதற்கு? தூய பக்தியின்றி இறைவனை அடைவது எப்படி குகேஸ்வரா?',
        'ml': 'ഹൃദയം ഉരുകാത്തവന്റെ പൂജ എന്തിനാണ്? ആത്മാർത്ഥ ഭക്തിയില്ലാതെ ഈശ്വരനെ പ്രീതിപ്പെടുത്താനാവില്ല ഗുഹേശ്വരാ.',
      },
      meaningByLang: {
        'kn': 'ಹೃದಯಪೂರ್ವಕ ಪ್ರೇಮ ಮತ್ತು ಶುದ್ಧ ಭಾವನೆಯೇ ಭಕ್ತಿಯ ಜೀವಾಳ. ಬಾಹ್ಯ ಕ್ರಿಯೆಗಳಿಗಿಂತ ಮನಸ್ಸಿನ ಪರಿಶುದ್ಧ ಸಮರ್ಪಣೆಯೇ ಮುಖ್ಯ.',
        'te': 'హృదయపూర్వక ప్రేమ, భావశుద్ధియే భక్తికి మూలం. బాహ్య ఆచారాల కంటే అంతరంగ పరిశుద్ధతే ముఖ్యం.',
        'en': 'Ritual without emotional surrender and inner purity is meaningless. Genuine devotion requires a melted, humble heart.',
        'hi': 'हृदय की सरलता और निष्कपट भाव ही सच्ची भक्ति का आधार is।',
        'ta': 'பக்தியில் மனத்தூய்மையும் உள்ளன்பும் மிக அவசியமாகும்.',
        'ml': 'ഹൃദയശുദ്ധിയോടെയുള്ള സമർപ്പണമാണ് ഭക്തിയുടെ കാതൽ.',
      },
    ),

    // 10. Purandara Dasa - Manava Janma Doddadu
    SacredWisdomItem(
      id: 'purandara_manavajanma',
      author: 'Purandara Dasa',
      authorKannada: 'ಪುರಂದರ ದಾಸರು',
      title: 'ಮಾನವ ಜನ್ಮದ ಹಿರಿಮೆ ಕೀರ್ತನೆ',
      deity: 'ಪುರಂದರ ವಿಠಲ',
      category: 'Dasa Sahitya',
      verseByLang: {
        'kn': 'ಮಾನವ ಜನ್ಮ ದೊಡ್ಡದು, ಇದ ಹಾನಿ ಮಾಡಲು ಬೇಡಿ ಹುಚ್ಚಪ್ಪಗಳಿರಾ ।\nಮನದಾಸೆಗಳ ಬಿಟ್ಟು ಹರಿಯ ಧ್ಯಾನವ ಮಾಡಿ,\nಕಂಡು ಕಂಡು ಕೈಬಿಡದ ಪುರಂದರವಿಠಲನ ನಂಬಿ ಬದುಕಿರೋ ॥',
        'te': 'మానవ జన్మ గొప్పది, దీనిని వృథా చేసుకోకండి ఓ జనులారా ।\nమనసులోని కోరికలను వీడి హరిని ధ్యానించండి,\nఎల్లప్పుడూ వెన్నంటి రక్షించే పురందరవిఠలుని నమ్మి జీవించండి ॥',
        'en': 'Mānava janma doḍḍadu, ida hāni māḍalu bēḍi huccappagaḷirā ।\nManadāsegaḷa biṭṭu hariya dhyānava māḍi,\nkaṇḍu kaṇḍu kaibiḍada Purandaraviṭhalana nambi badukirō ॥',
        'hi': 'मानव जन्म अत्यंत अनमोल है, इसे व्यर्थ मत गंवाओ। सांसारिक मोह त्यागकर भगवान श्रीहरि का ध्यान करो और प्रभु पुरंदर विठ्ठल पर विश्वास रखो।',
        'ta': 'மனிதப் பிறவி மிக மேலானது, அதை வீணாக்காதீர்கள். இறைவனைத் தியானித்து பிறவிப் பெருங்கடலைக் கடப்பீராக.',
        'ml': 'മനുഷ്യജന്മം അത്യന്തം ശ്രേഷ്ഠമാണ്, ഇത് വ്യർത്ഥമാക്കരുത്. ഭഗവാനെ ധ്യാനിച്ച് ആത്മസാക്ഷാത്കാരം നേടുക.',
      },
      meaningByLang: {
        'kn': 'ಅಪರೂಪವಾಗಿ ಲಭಿಸಿದ ಈ ಮಾನವ ಜನ್ಮವನ್ನು ವ್ಯರ್ಥ ಚಟುವಟಿಕೆಗಳಲ್ಲಿ ಕಳೆಯದೆ, ಸತ್ಕಾರ್ಯ ಮತ್ತು ಭಗವನ್ನಾಮ ಸ್ಮರಣೆಯಲ್ಲಿ ಸಾರ್ಥಕಗೊಳಿಸಿ.',
        'te': 'లభించిన అమూల్యమైన మానవ జన్మను వృథా చేయకుండా, సత్కార్యాలు మరియు భగవన్నామ స్మరణతో సార్థకం చేసుకోండి.',
        'en': 'Human birth is precious and rare; do not squander it in futile pursuits. Sanctify this life through noble deeds and constant remembrance of the Divine.',
        'hi': 'मानव जीवन एक दुर्लभ अवसर है। इसे सत्कर्म, परोपकार और ईश्वर भजन में लगाकर सार्थक बनाएं।',
        'ta': 'அரிதான மனிதப் பிறவியை வீணாக்காமல் நற்செயல்களாலும் இறை சிந்தனையாலும் சிறப்படையச் செய்யுங்கள்.',
        'ml': 'അപൂർവ്വമായ മനുഷ്യജന്മം സൽക്കർമ്മങ്ങളിലൂടെയും ഈശ്വരസ്മരണയിലൂടെയും സാർത്ഥകമാക്കുക.',
      },
    ),

    // 11. Kanakadasa - Tallanisadiru Kandya
    SacredWisdomItem(
      id: 'kanaka_tallanisadiru',
      author: 'Kanakadasa',
      authorKannada: 'ಕನಕದಾಸರು',
      title: 'ಅಭಯ ಮತ್ತು ನಂಬಿಕೆಯ ಕೀರ್ತನೆ',
      deity: 'ಕಾಗಿನೆಲೆಯಾದಿಕೇಶವ',
      category: 'Dasa Sahitya',
      verseByLang: {
        'kn': 'ತಲ್ಲಣಿಸದಿರು ಕಂಡ್ಯ ಎಲೊ ಮನವೇ, ಎಲ್ಲರನು ಸಲಹುವನು ಇದಕೆ ಸಂಶಯವಿಲ್ಲ ।\nಹುಟ್ಟಿಸಿದ ಸ್ವಾಮಿ ತಾ ಹೊಣೆಗಾರನಾಗಿರಲು ಕಷ್ಟಗಳೇಕೆ ನಿನಗೆ?\nಕಾಗಿನೆಲೆಯಾದಿಕೇಶವನು ಸಕಲರ ಪೊರೆಯುವನು ॥',
        'te': 'కలత చెందకు ఓ మనసా, అందరినీ భగవంతుడే రక్షిస్తాడు ఇందులో సందేహం లేదు ।\nసృష్టించిన స్వామియే బాధ్యత వహించగా నీకు కష్టాలెందుకు?\nకాగినెలె ఆదికేశవుడు సమస్త లోకాలను కాపాడును ॥',
        'en': 'Tallaṇisadiru kaṇḍya elo manavē, ellaranu salahuvanu idake saṁśayavilla ।\nHuṭṭisida swāmi tā hoṇegāranāgiralu kaṣṭagaḷēke ninage?\nKāgineleyādikēśavanu sakalara poreyuvanu ॥',
        'hi': 'हे मेरे मन, भयभीत मत हो! संसार के सभी जीवों का पालनहार परमात्मा ही है। जिसने जीवन दिया है, वही रक्षा भी करेगा। प्रभु पर अटूट विश्वास रखो।',
        'ta': 'மனமே கலங்காதே! அனைவரையும் காப்பவன் இறைவனே. படைத்தவன் காக்கத் தயங்கான், அவனில் நம்பிக்கை வை.',
        'ml': 'മനസ്സേ ഭയപ്പെടരുത്! എല്ലാവരെയും പരിപാലിക്കുന്നത് ഭഗവാനാണ്. ജീവൻ നൽകിയവൻ സംരക്ഷിക്കുകയും ചെയ്യും.',
      },
      meaningByLang: {
        'kn': 'ಚಿಂತೆ, ಆತಂಕಗಳನ್ನು ಬಿಟ್ಟು ಭಗವಂತನ ಸರ್ವವ್ಯಾಪಿ ಕೃಪೆಯಲ್ಲಿ ಅಚಲ ನಂಬಿಕೆಯಿಡಿ. ಸೃಷ್ಟಿಕರ್ತನೇ ಎಲ್ಲರನ್ನೂ ರಕ್ಷಿಸುವ ಪರಮ ರಕ್ಷಕ.',
        'te': 'చింతలను వీడి భగవంతుని అపార కరుణపై విశ్వాసముంచండి. సృష్టికర్తయే అందరినీ రక్షించే పరమ దాత.',
        'en': 'Do not despair or worry, O mind! The Supreme Lord who created you will unfailingly protect and sustain you. Have complete faith in His providence.',
        'hi': 'चिंता त्यागकर सर्वशक्तिमान परमात्मा की कृपा पर भरोसा रखें। वही सबका कल्याणकारी रक्षक है।',
        'ta': 'கவலையை விடுத்து இறைவனின் கருணையில் பூரண நம்பிக்கை வையுங்கள்.',
        'ml': 'ആകുಲതകൾ വെടിഞ്ഞ് ഭഗവാന്റെ കാരുണ്യത്തിൽ പൂർണ്ണമായി വിശ്വസിക്കുക.',
      },
    ),

    // 12. Sacred Gayatri Maha Mantra
    SacredWisdomItem(
      id: 'gayatri_mantra',
      author: 'Rishi Vishwamitra (Rigveda)',
      authorKannada: 'ಋಷಿ ವಿಶ್ವಾಮಿತ್ರ (ವೇದವಾಣಿ)',
      title: 'ಗಾಯತ್ರೀ ಮಹಾಮಂತ್ರ',
      deity: 'ಸವಿತೃ ದೇವತಾ',
      category: 'Shloka',
      verseByLang: {
        'kn': 'ಓಂ ಭೂರ್ಭುವಸ್ಸುವಃ । ತತ್ಸವಿತುರ್ವರೇಣ್ಯಂ ।\nಭರ್ಗೋ ದೇವಸ್ಯ ಧೀಮಹಿ । ಧಿಯೋ ಯೋ ನಃ ಪ್ರಚೋದಯಾತ್ ॥',
        'te': 'ఓం భూర్భువస్సువః । తత్సవితుర్వరేణ్యం ।\nభర్గో దేవస్య ధీమహి । ధియో యో నః ప్రచోదయాత్ ॥',
        'en': 'Om Bhur Bhuvaḥ Swaḥ । Tat-Savitur Vareṇyaṃ ।\nBhargo Devasya Dhīmahi । Dhiyo Yo Naḥ Prachodayāt ॥',
        'hi': 'ॐ भूर्भुवः स्वः । तत्सवितुर्वरेण्यं ।\nभर्गो देवस्य धीमहि । धियो यो नः प्रचोदयात् ॥',
        'ta': 'ஓம் பூர்புவஸ்ஸுவஹ । தத்ஸவிதுர்வரேண்யம் ।\nபர்கோ தேவஸ்ய தீமஹி । தியோ யோ நஹ் ப்ரசோதயாத் ॥',
        'ml': 'ഓം ഭൂർഭുവസ്സുവഃ । തത്സവിതുർവരേണ്യം ।\nഭർഗോ ദേവസ്യ ധീമഹി । ധിയോ യോ നഃ പ്രചോദയാത് ॥',
      },
      meaningByLang: {
        'kn': 'ಸಕಲ ಜಗತ್ತನ್ನು ಸೃಷ್ಟಿಸಿ ಪ್ರಕಾಶಿಸುವ ಆ ಪರಂಜ್ಯೋತಿಯನ್ನು ನಾವು ಧ್ಯಾನಿಸುತ್ತೇವೆ. ಆ ದೈವೀ ಪ್ರಕಾಶವು ನಮ್ಮ ಬುದ್ಧಿಯನ್ನು ಸನ್ಮಾರ್ಗದಲ್ಲಿ ಮುನ್ನಡೆಸಲಿ.',
        'te': 'సమస్త విశ్వాన్ని సృష్టించి ప్రకాశింపజేసే ఆ దివ్య సవితృ దేవుని తేజాన్ని ధ్యానిస్తున్నాము. ఆ దివ్య తేజస్సు మన బుద్ధిని సన్మార్గంలో నడిపించుగాక.',
        'en': 'We meditate on the supreme radiant light of the Divine Creator who illuminates the cosmos. May that divine light awaken and guide our intellect.',
        'hi': 'हम उस प्राणस्वरूप, दुःखनाशक, सुखस्वरूप, श्रेष्ठ, तेजस्वी परमपिता परमात्मा के दिव्य तेज का ध्यान करते हैं जो हमारी बुद्धि को सन्मार्ग पर प्रेरित करे।',
        'ta': 'அனைத்து உலகங்களையும் படைத்து ஒளिरச்செய்யும் அந்த பரம்பொருளை தியானிக்கிறோம். அந்த தெய்வீக ஒளி நமது புத்தியை நல்வழியில் செலுத்தட்டும்.',
        'ml': 'പ്രപഞ്ചത്തെ സൃഷ്ടിച്ചു പ്രകാശിപ്പിക്കുന്ന ആ പരമജ്യോതിയെ നാം ധ്യാനിക്കുന്നു. ആ ദൈവിക പ്രകാശം നമ്മുടെ ബുദ്ധിയെ സന്മാർഗ്ഗത്തിലേക്ക് നയിക്കട്ടെ.',
      },
    ),
  ];

  static List<SacredWisdomItem> get allWisdom => _wisdomCollection;

  /// Returns dynamic shloka/vachana that changes daily based on day of year
  static SacredWisdomItem getTodayWisdom([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    final startOfYear = DateTime(targetDate.year, 1, 1);
    final dayIndex = targetDate.difference(startOfYear).inDays;
    return _wisdomCollection[dayIndex % _wisdomCollection.length];
  }

  static SacredWisdomItem getWisdomForDate(DateTime date) => getTodayWisdom(date);
}
