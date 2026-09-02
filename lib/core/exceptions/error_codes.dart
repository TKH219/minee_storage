/// Business error codes returned by the backend in `response.data['code']`.
///
/// These mirror the contract used by the API. Add new codes here and map them
/// to a typed exception in [ErrorInterceptor].
class ServerErrorCodes {
  const ServerErrorCodes._();

  static const String unauthorised = 'UNAUTHORISED';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String tokenInvalid = 'TOKEN_INVALID';
  static const String wrongEmailOrPassword = 'WRONG_EMAIL_OR_PASSWORD';
  static const String wrongPassword = 'WRONG_PASSWORD';
  static const String userWasLocked = 'USER_WAS_LOCKED';
  static const String emailAlreadyExists = 'EMAIL_ALREADY_EXISTS';
  static const String userNameAlreadyExists = 'USERNAME_ALREADY_EXISTS';
  static const String quantityBelowDrawn = 'QUANTITY_BELOW_DRAWN';
  static const String insufficientStock = 'INSUFFICIENT_STOCK';
  static const String occurredBeforeArrival = 'OCCURRED_BEFORE_ARRIVAL';
  static const String feeNotAllowed = 'FEE_NOT_ALLOWED';
  static const String reversalBelowZero = 'REVERSAL_BELOW_ZERO';
  static const String reversalAboveReceived = 'REVERSAL_ABOVE_RECEIVED';
  static const String batchAlreadyDrawn = 'BATCH_ALREADY_DRAWN';
  static const String staleTransaction = 'STALE_TRANSACTION';
}
