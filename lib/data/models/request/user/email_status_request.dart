import 'package:json_annotation/json_annotation.dart';

part 'email_status_request.g.dart';

/// The body of `POST /rest/v1/rpc/email_status`.
///
/// `p_email` is the function's parameter name, not a column, so it is spelled
/// out rather than derived from the field.
@JsonSerializable(createFactory: false)
class EmailStatusRequest {
  const EmailStatusRequest({required this.email});

  @JsonKey(name: 'p_email')
  final String email;

  Map<String, dynamic> toJson() => _$EmailStatusRequestToJson(this);
}
