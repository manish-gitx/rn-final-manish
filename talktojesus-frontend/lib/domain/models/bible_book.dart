class BibleBook {
  final String name;
  final int totalChapters;

  const BibleBook({
    required this.name,
    required this.totalChapters,
  });
}

class BibleData {
  static const List<BibleBook> books = [
    BibleBook(name: 'Genesis', totalChapters: 50),
    BibleBook(name: 'Exodus', totalChapters: 40),
    BibleBook(name: 'Leviticus', totalChapters: 27),
    BibleBook(name: 'Numbers', totalChapters: 36),
    BibleBook(name: 'Deuteronomy', totalChapters: 34),
    BibleBook(name: 'Joshua', totalChapters: 24),
    BibleBook(name: 'Judges', totalChapters: 21),
    BibleBook(name: 'Ruth', totalChapters: 4),
    BibleBook(name: '1 Samuel', totalChapters: 31),
    BibleBook(name: '2 Samuel', totalChapters: 24),
    BibleBook(name: '1 Kings', totalChapters: 22),
    BibleBook(name: '2 Kings', totalChapters: 25),
    BibleBook(name: '1 Chronicles', totalChapters: 29),
    BibleBook(name: '2 Chronicles', totalChapters: 36),
    BibleBook(name: 'Ezra', totalChapters: 10),
    BibleBook(name: 'Nehemiah', totalChapters: 13),
    BibleBook(name: 'Esther', totalChapters: 10),
    BibleBook(name: 'Job', totalChapters: 42),
    BibleBook(name: 'Psalms', totalChapters: 150),
    BibleBook(name: 'Proverbs', totalChapters: 31),
  ];

  static const List<String> versions = [
    'NIV',
    'KJV',
    'ESV',
    'NKJV',
    'NLT',
    'NASB',
  ];
}