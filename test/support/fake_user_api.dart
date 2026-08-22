import 'package:mine_storage/data/data_sources/remote/user_api.dart';
import 'package:mine_storage/data/models/models.dart';

class FakeUserApi implements UserApi {
  FakeUserApi({this.userRows = const [], this.status = 'none'});

  List<UserModel> userRows;
  String status;

  final List<String> calls = [];
  final Map<String, String> lastQuery = {};
  Map<String, dynamic> lastPatch = {};
  Map<String, dynamic> lastRpcBody = {};

  @override
  Future<List<UserModel>> fetchUser({required String id, String select = '*'}) async {
    calls.add('fetchUser');
    lastQuery['id'] = id;
    return userRows;
  }

  @override
  Future<void> updateUser(String id, UpdateUserRequest request) async {
    calls.add('updateUser');
    lastQuery['id'] = id;
    lastPatch = request.toJson();
  }

  @override
  Future<String> emailStatus(EmailStatusRequest request) async {
    calls.add('emailStatus');
    lastRpcBody = request.toJson();
    return status;
  }
}
