import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:singleclin_mobile/features/credits/models/credit_transaction_model.dart';

enum HistoryPeriodFilter { all, today, week, month, quarter, year, custom }

enum HistoryTypeFilter { all, earned, spent, refunded, bonus, subscription }

enum HistorySourceFilter {
  all,
  subscription,
  referral,
  purchase,
  booking,
  cancel,
  bonus,
}

enum HistorySortOrder { newest, oldest, highestAmount, lowestAmount }

class CreditHistoryController extends GetxController {
  // Reactive variables
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _transactions = <CreditTransactionModel>[].obs;
  final _filteredTransactions = <CreditTransactionModel>[].obs;
  final _hasMoreData = true.obs;
  final _currentPage = 1.obs;

  // Filter states
  final _periodFilter = HistoryPeriodFilter.all.obs;
  final _typeFilter = HistoryTypeFilter.all.obs;
  final _sourceFilter = HistorySourceFilter.all.obs;
  final _sortOrder = HistorySortOrder.newest.obs;
  final _searchQuery = ''.obs;
  final _customDateRange = Rx<DateTimeRange?>(null);

  // Statistics
  final _totalEarned = 0.obs;
  final _totalSpent = 0.obs;
  final _monthlyStats = <String, Map<String, int>>{}.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  List<CreditTransactionModel> get transactions => _filteredTransactions;
  bool get hasMoreData => _hasMoreData.value;
  int get currentPage => _currentPage.value;

  // Filter getters
  HistoryPeriodFilter get periodFilter => _periodFilter.value;
  HistoryTypeFilter get typeFilter => _typeFilter.value;
  HistorySourceFilter get sourceFilter => _sourceFilter.value;
  HistorySortOrder get sortOrder => _sortOrder.value;
  String get searchQuery => _searchQuery.value;
  DateTimeRange? get customDateRange => _customDateRange.value;

  // Stats getters
  int get totalEarned => _totalEarned.value;
  int get totalSpent => _totalSpent.value;
  int get netBalance => totalEarned - totalSpent;
  Map<String, Map<String, int>> get monthlyStats => _monthlyStats;

  String get netBalanceDisplay {
    final String prefix = netBalance >= 0 ? '+' : '';
    return '$prefix$netBalance SG';
  }

  bool get hasActiveFilters {
    return periodFilter != HistoryPeriodFilter.all ||
        typeFilter != HistoryTypeFilter.all ||
        sourceFilter != HistorySourceFilter.all ||
        searchQuery.isNotEmpty;
  }

  int get activeFiltersCount {
    int count = 0;
    if (periodFilter != HistoryPeriodFilter.all) count++;
    if (typeFilter != HistoryTypeFilter.all) count++;
    if (sourceFilter != HistorySourceFilter.all) count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  @override
  void onInit() {
    super.onInit();
    loadTransactionHistory();
    _setupFilterListeners();
  }

  void _setupFilterListeners() {
    // Auto-filter when any filter changes
    ever(_periodFilter, (_) => _applyFilters());
    ever(_typeFilter, (_) => _applyFilters());
    ever(_sourceFilter, (_) => _applyFilters());
    ever(_sortOrder, (_) => _applyFilters());
    ever(_searchQuery, (_) => _applyFilters());
    ever(_customDateRange, (_) => _applyFilters());
  }

  Future<void> loadTransactionHistory({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _currentPage.value = 1;
        _hasMoreData.value = true;
        _transactions.clear();
      }

      _isLoading.value = true;

      // Mock API call - replace with actual service
      await Future.delayed(const Duration(seconds: 1));

      final mockTransactions = _generateMockTransactions();

      if (isRefresh) {
        _transactions.assignAll(mockTransactions);
      } else {
        _transactions.addAll(mockTransactions);
      }

      _calculateStatistics();
      _applyFilters();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar o histórico',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadMoreTransactions() async {
    if (!_hasMoreData.value || _isLoadingMore.value) return;

    try {
      _isLoadingMore.value = true;
      _currentPage.value++;

      // Mock API call for pagination
      await Future.delayed(const Duration(seconds: 1));

      // Simulate no more data after page 3
      if (_currentPage.value > 3) {
        _hasMoreData.value = false;
        return;
      }

      final moreTransactions = _generateMockTransactions(
        page: _currentPage.value,
      );
      _transactions.addAll(moreTransactions);

      _applyFilters();
    } catch (e) {
      _currentPage.value--;
      Get.snackbar(
        'Erro',
        'Não foi possível carregar mais transações',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoadingMore.value = false;
    }
  }

  void _applyFilters() {
    var filtered = List<CreditTransactionModel>.from(_transactions);

    // Apply period filter
    if (_periodFilter.value != HistoryPeriodFilter.all) {
      filtered = _filterByPeriod(filtered);
    }

    // Apply type filter
    if (_typeFilter.value != HistoryTypeFilter.all) {
      filtered = _filterByType(filtered);
    }

    // Apply source filter
    if (_sourceFilter.value != HistorySourceFilter.all) {
      filtered = _filterBySource(filtered);
    }

    // Apply search query
    if (_searchQuery.value.isNotEmpty) {
      filtered = _filterBySearchQuery(filtered);
    }

    // Apply sorting
    filtered = _sortTransactions(filtered);

    _filteredTransactions.assignAll(filtered);
    _updateFilteredStatistics(filtered);
  }

  List<CreditTransactionModel> _filterByPeriod(
    List<CreditTransactionModel> transactions,
  ) {
    final now = DateTime.now();
    late DateTime startDate;

    switch (_periodFilter.value) {
      case HistoryPeriodFilter.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case HistoryPeriodFilter.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case HistoryPeriodFilter.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case HistoryPeriodFilter.quarter:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case HistoryPeriodFilter.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case HistoryPeriodFilter.custom:
        if (_customDateRange.value == null) return transactions;
        return transactions
            .where(
              (t) =>
                  t.createdAt.isAfter(_customDateRange.value!.start) &&
                  t.createdAt.isBefore(
                    _customDateRange.value!.end.add(const Duration(days: 1)),
                  ),
            )
            .toList();
      case HistoryPeriodFilter.all:
      default:
        return transactions;
    }

    return transactions.where((t) => t.createdAt.isAfter(startDate)).toList();
  }

  List<CreditTransactionModel> _filterByType(
    List<CreditTransactionModel> transactions,
  ) {
    switch (_typeFilter.value) {
      case HistoryTypeFilter.earned:
        return transactions
            .where((t) => t.type == TransactionType.earned)
            .toList();
      case HistoryTypeFilter.spent:
        return transactions
            .where((t) => t.type == TransactionType.spent)
            .toList();
      case HistoryTypeFilter.refunded:
        return transactions
            .where((t) => t.type == TransactionType.refunded)
            .toList();
      case HistoryTypeFilter.bonus:
        return transactions
            .where((t) => t.type == TransactionType.bonus)
            .toList();
      case HistoryTypeFilter.subscription:
        return transactions
            .where((t) => t.type == TransactionType.subscription)
            .toList();
      case HistoryTypeFilter.all:
      default:
        return transactions;
    }
  }

  List<CreditTransactionModel> _filterBySource(
    List<CreditTransactionModel> transactions,
  ) {
    switch (_sourceFilter.value) {
      case HistorySourceFilter.subscription:
        return transactions
            .where((t) => t.source == TransactionSource.monthlySubscription)
            .toList();
      case HistorySourceFilter.referral:
        return transactions
            .where((t) => t.source == TransactionSource.referral)
            .toList();
      case HistorySourceFilter.purchase:
        return transactions
            .where((t) => t.source == TransactionSource.purchase)
            .toList();
      case HistorySourceFilter.booking:
        return transactions
            .where((t) => t.source == TransactionSource.appointmentBooking)
            .toList();
      case HistorySourceFilter.cancel:
        return transactions
            .where((t) => t.source == TransactionSource.appointmentCancel)
            .toList();
      case HistorySourceFilter.bonus:
        return transactions
            .where((t) => t.source == TransactionSource.bonus)
            .toList();
      case HistorySourceFilter.all:
      default:
        return transactions;
    }
  }

  List<CreditTransactionModel> _filterBySearchQuery(
    List<CreditTransactionModel> transactions,
  ) {
    final query = _searchQuery.value.toLowerCase();
    return transactions
        .where(
          (t) =>
              t.description.toLowerCase().contains(query) ||
              t.typeDisplayName.toLowerCase().contains(query) ||
              t.sourceDisplayName.toLowerCase().contains(query),
        )
        .toList();
  }

  List<CreditTransactionModel> _sortTransactions(
    List<CreditTransactionModel> transactions,
  ) {
    switch (_sortOrder.value) {
      case HistorySortOrder.newest:
        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case HistorySortOrder.oldest:
        transactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case HistorySortOrder.highestAmount:
        transactions.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
        break;
      case HistorySortOrder.lowestAmount:
        transactions.sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));
        break;
    }
    return transactions;
  }

  void setPeriodFilter(HistoryPeriodFilter filter) {
    _periodFilter.value = filter;
  }

  void setTypeFilter(HistoryTypeFilter filter) {
    _typeFilter.value = filter;
  }

  void setSourceFilter(HistorySourceFilter filter) {
    _sourceFilter.value = filter;
  }

  void setSortOrder(HistorySortOrder order) {
    _sortOrder.value = order;
  }

  void setSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void setCustomDateRange(DateTimeRange? dateRange) {
    _customDateRange.value = dateRange;
    if (dateRange != null) {
      _periodFilter.value = HistoryPeriodFilter.custom;
    }
  }

  void clearAllFilters() {
    _periodFilter.value = HistoryPeriodFilter.all;
    _typeFilter.value = HistoryTypeFilter.all;
    _sourceFilter.value = HistorySourceFilter.all;
    _searchQuery.value = '';
    _customDateRange.value = null;
    _sortOrder.value = HistorySortOrder.newest;
  }

  void _calculateStatistics() {
    int earned = 0;
    int spent = 0;
    final stats = <String, Map<String, int>>{};

    for (final transaction in _transactions) {
      if (transaction.isPositive) {
        earned += transaction.amount;
      } else {
        spent += transaction.amount.abs();
      }

      // Monthly statistics
      final monthKey =
          '${transaction.createdAt.year}-${transaction.createdAt.month.toString().padLeft(2, '0')}';
      stats[monthKey] ??= {'earned': 0, 'spent': 0};

      if (transaction.isPositive) {
        stats[monthKey]!['earned'] =
            stats[monthKey]!['earned']! + transaction.amount;
      } else {
        stats[monthKey]!['spent'] =
            stats[monthKey]!['spent']! + transaction.amount.abs();
      }
    }

    _totalEarned.value = earned;
    _totalSpent.value = spent;
    _monthlyStats.assignAll(stats);
  }

  void _updateFilteredStatistics(
    List<CreditTransactionModel> filteredTransactions,
  ) {
    // Update statistics based on filtered results if needed
    // This could be used to show filtered stats in UI
  }

  Future<void> exportHistory({String format = 'csv'}) async {
    try {
      _isLoading.value = true;

      // Mock export functionality
      await Future.delayed(const Duration(seconds: 2));

      Get.snackbar(
        'Sucesso',
        'Extrato exportado com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível exportar o extrato',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Mock data generation
  List<CreditTransactionModel> _generateMockTransactions({int page = 1}) {
    final transactions = <CreditTransactionModel>[];
    final now = DateTime.now();

    // Generate mock transactions based on page
    final baseIndex = (page - 1) * 20;

    for (int i = 0; i < 20; i++) {
      final index = baseIndex + i;
      final daysBack = index * 2;

      transactions.add(
        CreditTransactionModel(
          id: 'tx_${index + 1}',
          userId: 'user123',
          amount: _getMockAmount(index),
          balanceAfter: 245 - (index * 5),
          type: _getMockTransactionType(index),
          source: _getMockTransactionSource(index),
          description: _getMockDescription(index),
          relatedEntityId: 'entity_${index + 1}',
          relatedEntityType: _getMockEntityType(index),
          createdAt: now.subtract(Duration(days: daysBack, hours: index % 24)),
        ),
      );
    }

    return transactions;
  }

  int _getMockAmount(int index) {
    final amounts = [200, -25, 10, -30, 15, -20, 50, -35, 5, -40];
    return amounts[index % amounts.length];
  }

  TransactionType _getMockTransactionType(int index) {
    final types = [
      TransactionType.subscription,
      TransactionType.spent,
      TransactionType.bonus,
      TransactionType.spent,
      TransactionType.refunded,
    ];
    return types[index % types.length];
  }

  TransactionSource _getMockTransactionSource(int index) {
    final sources = [
      TransactionSource.monthlySubscription,
      TransactionSource.appointmentBooking,
      TransactionSource.referral,
      TransactionSource.appointmentBooking,
      TransactionSource.appointmentCancel,
    ];
    return sources[index % sources.length];
  }

  String _getMockDescription(int index) {
    final descriptions = [
      'Renovação da assinatura Premium',
      'Consulta - Dr. Silva Cardiologia',
      'Bônus por indicação - Maria Santos',
      'Exame - Clínica Vida Saudável',
      'Reembolso - Cancelamento de consulta',
      'Consulta - Dra. Ana Dermatologia',
      'Compra de créditos extras',
      'Procedimento - Clínica Estética',
      'Bônus de fidelidade',
      'Consulta - Dr. João Ortopedia',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getMockEntityType(int index) {
    final types = [
      'subscription',
      'appointment',
      'referral',
      'appointment',
      'appointment',
    ];
    return types[index % types.length];
  }
}
