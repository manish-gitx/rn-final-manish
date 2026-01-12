/// Tester account configuration
class TesterConstants {
  /// Hardcoded JWT token for tester account
  /// This token is used for all API calls when the user is a tester
  static const String testerJwtToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJkMTRhZmQwMy1mMDRlLTQzM2UtOTFkOS05MDlkYzUzYmVlMjMiLCJpYXQiOjE3NjI0MjQzMDYsImV4cCI6MTc5Mzk2MDMwNn0.o8BccbLc8Vx-Ju47uC7owOGXeMKwbQxN1GR0unGdH7o';

  /// Tester user ID from the JWT payload
  static const String testerUserId = 'd14afd03-f04e-433e-91d9-909dc53bee23';

  /// Check if a user ID is a tester account
  static bool isTesterUser(String userId) {
    return userId == testerUserId;
  }
}
