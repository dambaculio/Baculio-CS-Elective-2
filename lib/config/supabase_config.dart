/// Supabase project credentials.
///
/// Get both values from your Supabase Dashboard:
///   Project Settings -> API (or the "Connect" button at the top)
///
/// Use ONLY the public key here: the "anon" key, or the newer
/// "publishable" key that starts with `sb_publishable_`. It is meant
/// to live in client apps; Row Level Security protects the data.
/// NEVER paste the service_role / secret key into the app.
class SupabaseConfig {
  static const String url = 'https://rlalghybnfdhuxgfrfem.supabase.co';
  static const String anonKey = 'sb_publishable_AEZNWrQ_dx5Sp3kSFslKlA_Gqp-uYrW';
}
