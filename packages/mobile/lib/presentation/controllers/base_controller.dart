import 'package:get/get.dart';
import 'package:mobile/core/errors/failures.dart';

/// Base controller that all controllers should extend
/// Provides common functionality for loading states and error handling
abstract class BaseController extends GetxController {
  // Loading state management
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error state management
  final Rxn<Failure> _error = Rxn<Failure>();
  Failure? get error => _error.value;

  // Success message management
  final RxnString _successMessage = RxnString();
  String? get successMessage => _successMessage.value;

  /// Sets loading state
  void setLoading(bool value) {
    _isLoading.value = value;
  }

  /// Sets error state
  void setError(Failure? failure) {
    _error.value = failure;
    if (failure != null) {
      // Show error snackbar
      showErrorSnackbar(failure.message);
    }
  }

  /// Clears error state
  void clearError() {
    _error.value = null;
  }

  /// Sets success message
  void setSuccessMessage(String? message) {
    _successMessage.value = message;
    if (message != null) {
      // Show success snackbar
      showSuccessSnackbar(message);
    }
  }

  /// Clears success message
  void clearSuccessMessage() {
    _successMessage.value = null;
  }

  /// Execute an async operation with loading and error handling
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    bool showError = true,
    void Function(T result)? onSuccess,
    void Function(Failure failure)? onError,
  }) async {
    try {
      if (showLoading) {
        setLoading(true);
      }
      clearError();

      final result = await operation();

      if (onSuccess != null) {
        onSuccess(result);
      }

      return result;
    } on Exception catch (e) {
      final failure = _mapExceptionToFailure(e);

      if (showError) {
        setError(failure);
      }

      if (onError != null) {
        onError(failure);
      }

      return null;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
    }
  }

  /// Maps exceptions to failures
  Failure _mapExceptionToFailure(Exception e) {
    // TODO(error): Add specific exception mapping
    return UnknownFailure(message: e.toString(), details: e);
  }

  /// Shows error snackbar
  void showErrorSnackbar(String message) {
    Get.snackbar('Erro', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Shows success snackbar
  void showSuccessSnackbar(String message) {
    Get.snackbar('Sucesso', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Shows info snackbar
  void showInfoSnackbar(String message) {
    Get.snackbar('Informação', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Shows warning snackbar
  void showWarningSnackbar(String message) {
    Get.snackbar('Atenção', message, snackPosition: SnackPosition.BOTTOM);
  }
}
