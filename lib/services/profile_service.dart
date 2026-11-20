import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  static const String _select = 'id, email, firstname, lastname, roles(role)';

  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select(_select)
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  Future<Map<String, Profile>> fetchProfiles(Iterable<String> userIds) async {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from('profiles')
        .select(_select)
        .inFilter('id', ids);
    return {for (final row in rows) row['id'] as String: Profile.fromMap(row)};
  }
}
