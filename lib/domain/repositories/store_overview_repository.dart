import 'package:mine_storage/domain/entities/entities.dart';

/// Every store the signed-in user can act in, with the figures the switcher
/// shows beside each one.
///
/// Separate from [StoreRepository] because it spans stores by design, while
/// every other read is scoped to exactly one.
abstract class StoreOverviewRepository {
  Future<List<StoreSummary>> summaries();
}
