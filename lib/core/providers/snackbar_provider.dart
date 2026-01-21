import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/services/snackbar/snackbar_service.dart';

final snackbarServiceProvider = Provider<SnackbarService>((ref) {
  return SnackbarService();
});
