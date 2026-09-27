import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Redirect utilisé par l'application mobile après :
  /// - confirmation de l'email
  /// - connexion Google
  /// - réinitialisation du mot de passe
  static const String redirectUrl = 'io.olten.app://login-callback/';

  SupabaseClient get client => Supabase.instance.client;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => client.auth.currentUser;

  Session? get currentSession => client.auth.currentSession;

  bool get isAuthenticated => currentUser != null;

  String? get currentUserId => currentUser?.id;

  String? get currentUserEmail => currentUser?.email;

  String? get currentUserName {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata;

    final fullName = metadata?['full_name']?.toString();

    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    final name = metadata?['name']?.toString();

    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    return null;
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    return client.auth.signUp(
      email: cleanEmail,
      password: password,

      // Après confirmation de l'email,
      // Supabase redirige vers l'application Flutter.
      emailRedirectTo: redirectUrl,

      data: {
        'full_name': cleanName,
        'name': cleanName,
      },
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    return client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<bool> signInWithGoogle() async {
    return client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await client.auth.signOut();
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> resetPassword({
    required String email,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    await client.auth.resetPasswordForEmail(
      cleanEmail,
      redirectTo: redirectUrl,
    );
  }

  // ============================================================
  // UPDATE PASSWORD
  // ============================================================

  Future<UserResponse> updatePassword(
    String password,
  ) async {
    return client.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
  }

  // ============================================================
  // UPDATE NAME
  // ============================================================

  Future<UserResponse> updateName(
    String name,
  ) async {
    final cleanName = name.trim();

    return client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': cleanName,
          'name': cleanName,
        },
      ),
    );
  }

  // ============================================================
  // UPDATE METADATA
  // ============================================================

  Future<UserResponse> updateMetadata(
    Map<String, dynamic> metadata,
  ) async {
    return client.auth.updateUser(
      UserAttributes(
        data: metadata,
      ),
    );
  }

  // ============================================================
  // EMAIL CONFIRMATION
  // ============================================================

  bool get isEmailConfirmed {
    final user = currentUser;

    if (user == null) {
      return false;
    }

    return user.emailConfirmedAt != null;
  }

  // ============================================================
  // USER NAME
  // ============================================================

  String getNameFromUser(User user) {
    final metadata = user.userMetadata;

    final fullName = metadata?['full_name']?.toString();

    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    final name = metadata?['name']?.toString();

    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    if (user.email != null && user.email!.contains('@')) {
      return user.email!.split('@').first;
    }

    return '';
  }

  // ============================================================
  // AUTH STATE
  // ============================================================

  Stream<AuthState> get authStateChanges {
    return client.auth.onAuthStateChange;
  }

  // ============================================================
  // PROVIDER
  // ============================================================

  String? get provider {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final identities = user.identities;

    if (identities == null || identities.isEmpty) {
      return null;
    }

    return identities.first.provider;
  }

  // ============================================================
  // GOOGLE USER
  // ============================================================

  bool get isGoogleUser {
    return provider == 'google';
  }
}
