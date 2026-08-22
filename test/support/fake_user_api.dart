import 'package:mine_storage/data/data_sources/remote/user_api.dart';

class FakeUserApi implements UserApi {
  FakeUserApi({this.userRows = const [], this.status = 'none'});

  List<Map<String, dynamic>> userRows;
  String status;

  final List<String> calls = [];
  final Map<String, String> lastQuery = {};
  Map<String, dynamic> lastPatch = {};
  Map<String, dynamic> lastRpcBody = {};

  @override
  Future<dynamic> fetchUser({required String id, String select = '*'}) async {
    calls.add('fetchUser');
    lastQuery['id'] = id;
    return userRows;
  }

  @override
  Future<void> updateUser(String id, Map<String, dynamic> values) async {
    calls.add('updateUser');
    lastQuery['id'] = id;
    lastPatch = values;
  }

  @override
  Future<String> emailStatus(Map<String, dynamic> body) async {
    calls.add('emailStatus');
    lastRpcBody = body;
    return status;
  }
}
