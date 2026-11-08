/// All route paths in one place.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const signIn = '/sign-in';
  static const profiles = '/profiles';
  static const createProfile = '/profiles/new';
  static const home = '/home';

  // Route patterns (used in GoRoute)
  static const track = '/track/:trackId';
  static const level = '/track/:trackId/level/:levelId';
  static const play = '/track/:trackId/level/:levelId/play';

  // Paths to navigate to
  static String trackPath(String trackId) => '/track/$trackId';
  static String levelPath(String trackId, String levelId) =>
      '/track/$trackId/level/$levelId';
  static String playPath(String trackId, String levelId) =>
      '/track/$trackId/level/$levelId/play';
}
