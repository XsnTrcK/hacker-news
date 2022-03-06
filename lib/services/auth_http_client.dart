// ignore: import_of_legacy_library_into_null_safe
import 'package:http/http.dart';

// TODO: Handle authenticated calls once login supported
class AuthenticatedHttpClient extends BaseClient {
  final Client _defaultClient;

  AuthenticatedHttpClient() : _defaultClient = Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) =>
      _defaultClient.send(request);
}
