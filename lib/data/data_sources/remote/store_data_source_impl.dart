import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/data/data_sources/remote/store_data_source.dart';

class StoreDataSourceImpl implements StoreDataSource {
  StoreDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchMine(String ownerId) async {
    final rows = await _client
        .from('stores')
        .select()
        .eq('owner_id', ownerId)
        .eq('is_archived', false)
        .order('created_at');
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final rows = await _client.from('store_categories').select().order('sort_order');
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> insertStore(Map<String, dynamic> values) async {
    return _client.from('stores').insert(values).select().single();
  }
}
