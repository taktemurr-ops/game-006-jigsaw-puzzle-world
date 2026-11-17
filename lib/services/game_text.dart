/// Small zero-dependency multilingual UI lexicon. RTL is handled by Flutter
/// Directionality so language switching does not require online services.
class GameText {
  const GameText(this.language);
  final String language;
  static const _translations = <String, Map<String, String>>{
    'tr': {
      'title': 'Yapboz Dünyası', 'subtitle': 'Resmi parçaları yerlerine taşıyarak tamamla.',
      'classic': 'Klasik', 'timed': 'Zamana karşı', 'zen': 'Rahat', 'daily': 'Günlük',
      'slide': 'Kaydırmalı', 'jigsaw': 'Resimli yapboz', 'new': 'Yeni oyun',
      'undo': 'Geri al', 'hint': 'İpucu', 'preview': 'Resmi göster',
      'moves': 'Hamle', 'time': 'Süre', 'done': 'Tebrikler, tamamlandı!',
      'timeout': 'Süre doldu!', 'pause': 'Duraklat', 'resume': 'Devam et',
      'settings': 'Ayarlar', 'level': 'Zorluk', 'theme': 'Resim',
      'numbers': 'Parça numaralarını göster', 'sound': 'Ses efektleri',
      'motion': 'Azaltılmış hareket', 'language': 'Dil',
      'erase': 'Yerel verileri sil', 'privacy': 'Çevrimdışı çalışır. Kişisel veri gönderilmez.',
      'cancel': 'İptal', 'confirm': 'Onayla', 'clearTitle': 'Tüm ilerleme silinsin mi?',
      'select': 'İki parçaya sırayla dokunarak yer değiştir.',
      'best': 'En iyi skor', 'noAds': 'Reklamlar etkin değil',
      'gallery': 'Resim galerisi', 'art1': 'Dağlar', 'art2': 'Okyanus',
      'art3': 'Bahçe', 'art4': 'Gün batımı', 'retry': 'Tekrar oyna',
    },
    'en': {
      'title': 'Jigsaw Puzzle World', 'subtitle': 'Reassemble the picture by swapping tiles.',
      'classic': 'Classic', 'timed': 'Timed', 'zen': 'Zen', 'daily': 'Daily',
      'slide': 'Sliding', 'jigsaw': 'Picture puzzle', 'new': 'New game',
      'undo': 'Undo', 'hint': 'Hint', 'preview': 'Preview',
      'moves': 'Moves', 'time': 'Time', 'done': 'Puzzle complete!',
      'timeout': 'Time is up!', 'pause': 'Pause', 'resume': 'Resume',
      'settings': 'Settings', 'level': 'Difficulty', 'theme': 'Artwork',
      'numbers': 'Show piece numbers', 'sound': 'Sound effects',
      'motion': 'Reduced motion', 'language': 'Language',
      'erase': 'Delete local data', 'privacy': 'Works offline. No personal data is uploaded.',
      'cancel': 'Cancel', 'confirm': 'Confirm', 'clearTitle': 'Delete all progress?',
      'select': 'Tap two pieces to swap their positions.',
      'best': 'Best', 'noAds': 'Ads are disabled',
      'gallery': 'Artwork gallery', 'art1': 'Mountains', 'art2': 'Ocean',
      'art3': 'Garden', 'art4': 'Sunset', 'retry': 'Play again',
    },
    'ar': {
      'title': 'عالم الألغاز المصورة', 'subtitle': 'أعد ترتيب قطع الصورة لإكمال اللغز.',
      'classic': 'كلاسيكي', 'timed': 'ضد الوقت', 'zen': 'هادئ', 'daily': 'يومي',
      'slide': 'انزلاق', 'jigsaw': 'صورة', 'new': 'لعبة جديدة',
      'undo': 'تراجع', 'hint': 'تلميح', 'preview': 'معاينة',
      'moves': 'الحركات', 'time': 'الوقت', 'done': 'اكتمل اللغز!',
      'timeout': 'انتهى الوقت!', 'pause': 'إيقاف', 'resume': 'متابعة',
      'settings': 'الإعدادات', 'level': 'الصعوبة', 'theme': 'الصورة',
      'numbers': 'عرض أرقام القطع', 'sound': 'المؤثرات الصوتية',
      'motion': 'تقليل الحركة', 'language': 'اللغة',
      'erase': 'حذف البيانات المحلية', 'privacy': 'تعمل دون إنترنت. لا تُرسل بيانات شخصية.',
      'cancel': 'إلغاء', 'confirm': 'تأكيد', 'clearTitle': 'حذف كل التقدم؟',
      'select': 'اضغط قطعتين لتبديل موضعهما.',
      'best': 'الأفضل', 'noAds': 'الإعلانات معطلة',
      'gallery': 'معرض الصور', 'art1': 'الجبال', 'art2': 'المحيط',
      'art3': 'الحديقة', 'art4': 'الغروب', 'retry': 'العب مجددًا',
    },
  };
  String t(String key) => _translations[language]?[key] ?? _translations['en']?[key] ?? key;
  bool get isRtl => language == 'ar';
}
