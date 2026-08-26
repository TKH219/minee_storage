import 'package:mine_storage/domain/entities/entities.dart';

/// The ledger. **The only write path into a lot's remaining quantity** — after
/// this feature, anything else touching it is a bug.
abstract class TransactionRepository {
  /// One page, grouped by day. Every day header carries the subtotal for the
  /// **whole** day, computed server-side, so a day split across two pages shows
  /// the same figure on both.
  Future<TransactionPage> list({
    required String storeId,
    TransactionType? type,
    DateTime? from,
    DateTime? to,
    String? productId,
    PaymentMethod? paymentMethod,
    String? query,
    int page = 1,
    int limit = 20,
  });

  Future<Transaction> byId(String id);

  /// Resolves the allocation, applies every signed delta and freezes the money,
  /// in one database transaction.
  Future<Transaction> create(TransactionDraft draft);

  /// Reverses the existing lines and applies the new ones, in one database
  /// transaction. [expectedUpdatedAt] is the optimistic lock: pass the stamp
  /// the entity was read with, and a stale value is refused with
  /// [StaleTransactionException] having changed nothing.
  ///
  /// Because later transactions are never replayed, an amend may resolve onto
  /// a different lot set than the original — call [preview] first and show the
  /// difference before committing.
  Future<Transaction> amend(
    String id,
    TransactionDraft draft, {
    required DateTime expectedUpdatedAt,
  });

  /// Stamps the deletion and returns every quantity to the lot it came from.
  /// Refused whole with [ReversalBlockedException] when that stock has already
  /// left. The code is never released.
  Future<Transaction> remove(String id, {required DateTime expectedUpdatedAt});

  /// Resolves allocation and money without writing. The same code computes this
  /// and the commit, so the previewed total is the stored total.
  Future<TransactionPreview> preview(TransactionDraft draft);
}

/// The fees a store applies often enough to keep. Seeded per store; there is no
/// screen to curate them yet.
abstract class FeePresetRepository {
  Future<List<FeePreset>> presetsFor(String storeId);
  Future<FeePreset> create(FeePreset preset);
  Future<FeePreset> update(FeePreset preset);
  Future<void> remove(String id);
}
