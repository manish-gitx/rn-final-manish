class BibleTranslation {
  final String id;
  final String name;
  final String englishName;
  final String website;
  final String licenseUrl;
  final String shortName;
  final String language;
  final String? languageName;
  final String? languageEnglishName;
  final String textDirection;
  final List<String> availableFormats;
  final String listOfBooksApiLink;
  final int numberOfBooks;
  final int totalNumberOfChapters;
  final int totalNumberOfVerses;

  BibleTranslation({
    required this.id,
    required this.name,
    required this.englishName,
    required this.website,
    required this.licenseUrl,
    required this.shortName,
    required this.language,
    this.languageName,
    this.languageEnglishName,
    required this.textDirection,
    required this.availableFormats,
    required this.listOfBooksApiLink,
    required this.numberOfBooks,
    required this.totalNumberOfChapters,
    required this.totalNumberOfVerses,
  });

  factory BibleTranslation.fromJson(Map<String, dynamic> json) {
    return BibleTranslation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      englishName: json['englishName'] as String? ?? '',
      website: json['website'] as String? ?? '',
      licenseUrl: json['licenseUrl'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      language: json['language'] as String? ?? '',
      languageName: json['languageName'] as String?,
      languageEnglishName: json['languageEnglishName'] as String?,
      textDirection: json['textDirection'] as String? ?? 'ltr',
      availableFormats: (json['availableFormats'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      listOfBooksApiLink: json['listOfBooksApiLink'] as String? ?? '',
      numberOfBooks: json['numberOfBooks'] as int? ?? 0,
      totalNumberOfChapters: json['totalNumberOfChapters'] as int? ?? 0,
      totalNumberOfVerses: json['totalNumberOfVerses'] as int? ?? 0,
    );
  }
}

class BibleBook {
  final String id;
  final String name;
  final String commonName;
  final String? title;
  final int order;
  final int numberOfChapters;
  final String firstChapterApiLink;
  final String lastChapterApiLink;
  final int totalNumberOfVerses;
  final bool? isApocryphal;

  BibleBook({
    required this.id,
    required this.name,
    required this.commonName,
    this.title,
    required this.order,
    required this.numberOfChapters,
    required this.firstChapterApiLink,
    required this.lastChapterApiLink,
    required this.totalNumberOfVerses,
    this.isApocryphal,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      commonName: json['commonName'] as String? ?? '',
      title: json['title'] as String?,
      order: json['order'] as int? ?? 0,
      numberOfChapters: json['numberOfChapters'] as int? ?? 0,
      firstChapterApiLink: json['firstChapterApiLink'] as String? ?? '',
      lastChapterApiLink: json['lastChapterApiLink'] as String? ?? '',
      totalNumberOfVerses: json['totalNumberOfVerses'] as int? ?? 0,
      isApocryphal: json['isApocryphal'] as bool?,
    );
  }
}

class BibleChapter {
  final BibleTranslation translation;
  final BibleBook book;
  final ChapterData chapter;

  BibleChapter({
    required this.translation,
    required this.book,
    required this.chapter,
  });

  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    return BibleChapter(
      translation: BibleTranslation.fromJson(json['translation'] as Map<String, dynamic>),
      book: BibleBook.fromJson(json['book'] as Map<String, dynamic>),
      chapter: ChapterData.fromJson(json['chapter'] as Map<String, dynamic>),
    );
  }
}

class ChapterData {
  final int number;
  final List<ChapterContent> content;
  final List<ChapterFootnote> footnotes;
  final String? thisChapterLink;
  final String? nextChapterApiLink;
  final String? previousChapterApiLink;
  final int numberOfVerses;

  ChapterData({
    required this.number,
    required this.content,
    required this.footnotes,
    this.thisChapterLink,
    this.nextChapterApiLink,
    this.previousChapterApiLink,
    required this.numberOfVerses,
  });

  factory ChapterData.fromJson(Map<String, dynamic> json) {
    return ChapterData(
      number: json['number'] as int? ?? 0,
      content: (json['content'] as List<dynamic>?)
          ?.map((e) => ChapterContent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      footnotes: (json['footnotes'] as List<dynamic>?)
          ?.map((e) => ChapterFootnote.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      thisChapterLink: json['thisChapterLink'] as String?,
      nextChapterApiLink: json['nextChapterApiLink'] as String?,
      previousChapterApiLink: json['previousChapterApiLink'] as String?,
      numberOfVerses: json['numberOfVerses'] as int? ?? 0,
    );
  }
}

abstract class ChapterContent {
  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'heading':
        return ChapterHeading.fromJson(json);
      case 'line_break':
        return ChapterLineBreak();
      case 'verse':
        return ChapterVerse.fromJson(json);
      case 'hebrew_subtitle':
        return ChapterHebrewSubtitle.fromJson(json);
      default:
        throw Exception('Unknown chapter content type: $type');
    }
  }
}

class ChapterHeading implements ChapterContent {
  final List<String> content;

  ChapterHeading({required this.content});

  factory ChapterHeading.fromJson(Map<String, dynamic> json) {
    return ChapterHeading(
      content: (json['content'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

class ChapterLineBreak implements ChapterContent {
  ChapterLineBreak();
}

class ChapterHebrewSubtitle implements ChapterContent {
  final List<dynamic> content;

  ChapterHebrewSubtitle({required this.content});

  factory ChapterHebrewSubtitle.fromJson(Map<String, dynamic> json) {
    return ChapterHebrewSubtitle(
      content: json['content'] as List<dynamic>,
    );
  }
}

class ChapterVerse implements ChapterContent {
  final int number;
  final List<dynamic> content;

  ChapterVerse({
    required this.number,
    required this.content,
  });

  factory ChapterVerse.fromJson(Map<String, dynamic> json) {
    return ChapterVerse(
      number: json['number'] as int,
      content: json['content'] as List<dynamic>,
    );
  }
}

class ChapterFootnote {
  final int noteId;
  final String text;
  final Map<String, dynamic>? reference;
  final String? caller;

  ChapterFootnote({
    required this.noteId,
    required this.text,
    this.reference,
    this.caller,
  });

  factory ChapterFootnote.fromJson(Map<String, dynamic> json) {
    return ChapterFootnote(
      noteId: json['noteId'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      reference: json['reference'] as Map<String, dynamic>?,
      caller: json['caller'] as String?,
    );
  }
}