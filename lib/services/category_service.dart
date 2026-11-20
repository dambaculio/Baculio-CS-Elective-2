import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../utils/errors.dart';

class CategoryService {
  CategoryService(this._client);

  final SupabaseClient _client;

  static const String _table = 'categories';

  Future<List<ProductCategory>> fetchAll() async {
    final rows = await _client
        .from(_table)
        .select('id, name')
        .order('name', ascending: true);
    return rows.map(ProductCategory.fromMap).toList();
  }

  Future<ProductCategory> create(String name) async {
    final row = await _client
        .from(_table)
        .insert({'name': name.trim()})
        .select('id, name')
        .single();
    return ProductCategory.fromMap(row);
  }

  Future<ProductCategory> rename(int id, String name) async {
    final row = await _client
        .from(_table)
        .update({'name': name.trim()})
        .eq('id', id)
        .select('id, name')
        .maybeSingle();
    if (row == null) {
      throw const AppException(
        "You don't have permission to edit categories.",
        permissionDenied: true,
      );
    }
    return ProductCategory.fromMap(row);
  }

  Future<void> delete(int id) async {
    final deleted = await _client
        .from(_table)
        .delete()
        .eq('id', id)
        .select('id');
    if (deleted.isEmpty) {
      throw const AppException(
        "You don't have permission to delete categories.",
        permissionDenied: true,
      );
    }
  }
}
