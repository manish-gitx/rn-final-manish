enum AppLanguage {
  english('EN', 'English'),
  telugu('తె', 'Telugu');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);
}