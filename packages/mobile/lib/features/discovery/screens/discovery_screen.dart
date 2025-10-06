import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/discovery/controllers/discovery_controller.dart';
import 'package:singleclin_mobile/features/discovery/controllers/filters_controller.dart';
import 'package:singleclin_mobile/features/discovery/screens/clinic_details_screen.dart';
import 'package:singleclin_mobile/features/discovery/screens/filters_screen.dart';
import 'package:singleclin_mobile/features/discovery/screens/map_view_screen.dart';
import 'package:singleclin_mobile/features/discovery/widgets/clinic_card.dart';
import 'package:singleclin_mobile/shared/widgets/custom_app_bar.dart';
import 'package:singleclin_mobile/shared/widgets/custom_bottom_nav.dart';

/// Main discovery screen with dual view mode (list/map) and search functionality
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  final DiscoveryController controller = Get.put(DiscoveryController());
  final FiltersController filtersController = Get.put(FiltersController());

  final TextEditingController _searchController = TextEditingController();
  final PagingController<int, Clinic> _pagingController = PagingController(
    firstPageKey: 0,
  );

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _setupPagination();
    _setupSearchListener();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _setupPagination() {
    _pagingController.addPageRequestListener((pageKey) {
      if (pageKey > 0) {
        controller.loadMoreClinics();
      }
    });

    // Listen to clinic updates
    ever(controller.filteredClinics, (List<Clinic> clinics) {
      if (controller.currentPage == 1) {
        _pagingController.refresh();
        _pagingController.appendPage(
          clinics,
          controller.hasMoreData ? 1 : null,
        );
      } else {
        final newClinics = clinics
            .skip((controller.currentPage - 1) * 20)
            .toList();
        if (newClinics.isNotEmpty) {
          _pagingController.appendPage(
            newClinics,
            controller.hasMoreData ? controller.currentPage : null,
          );
        }
      }
    });
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      controller.updateSearchQuery(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildFiltersRow(),
              _buildViewModeToggle(),
              Expanded(child: Obx(_buildContent)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }

  Widget _buildAppBar() {
    return CustomAppBar(
      title: 'Descobrir',
      showBackButton: false,
      actions: [
        Obx(() {
          final hasActiveFilters = controller.hasActiveFilters;
          return Stack(
            children: [
              IconButton(icon: const Icon(Icons.tune), onPressed: _openFilters),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.sgPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar clínicas, procedimentos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() {
            if (controller.hasSearchQuery) {
              return IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  controller.updateSearchQuery('');
                },
              );
            }
            return const SizedBox.shrink();
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: controller.updateSearchQuery,
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickFilterChip('Próximo', Icons.location_on),
                _buildQuickFilterChip('Hoje', Icons.today),
                _buildQuickFilterChip('Até 100SG', Icons.monetization_on),
                _buildQuickFilterChip('4★+', Icons.star),
                _buildQuickFilterChip('Estética', Icons.face),
                _buildQuickFilterChip('Injetáveis', Icons.medical_services),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final activeCount = controller.filterOptions.activeFiltersCount;
            return OutlinedButton.icon(
              onPressed: _openFilters,
              icon: const Icon(Icons.filter_list, size: 16),
              label: Text(activeCount > 0 ? '($activeCount)' : 'Filtros'),
              style: OutlinedButton.styleFrom(
                foregroundColor: activeCount > 0
                    ? AppColors.primary
                    : AppColors.mediumGrey,
                side: BorderSide(
                  color: activeCount > 0
                      ? AppColors.primary
                      : AppColors.lightGrey,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Obx(() {
        final isSelected = _isQuickFilterSelected(label);
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _applyQuickFilter(label);
            } else {
              _clearQuickFilter(label);
            }
          },
          backgroundColor: Colors.white,
          selectedColor: AppColors.primary.withOpacity(0.1),
          checkmarkColor: AppColors.primary,
        );
      }),
    );
  }

  bool _isQuickFilterSelected(String filterName) {
    final filters = controller.filterOptions;
    switch (filterName) {
      case 'Hoje':
        return filters.availability.todayOnly == true;
      case 'Até 100SG':
        return filters.priceRange.maxPrice != null &&
            filters.priceRange.maxPrice! <= 100;
      case '4★+':
        return filters.rating.minimumRating != null &&
            filters.rating.minimumRating! >= 4.0;
      case 'Estética':
        return filters.categories.selectedCategories.contains(
          'Estética Facial',
        );
      case 'Injetáveis':
        return filters.categories.selectedCategories.contains(
          'Terapias Injetáveis',
        );
      default:
        return false;
    }
  }

  void _clearQuickFilter(String filterName) {
    switch (filterName) {
      case 'Hoje':
        filtersController.setAvailabilityToday(false);
        _applyFiltersToDiscovery();
        break;
      case 'Até 100SG':
        filtersController.updatePriceRange(const RangeValues(0, 500));
        _applyFiltersToDiscovery();
        break;
      case '4★+':
        filtersController.updateMinimumRating(0.0);
        _applyFiltersToDiscovery();
        break;
      case 'Estética':
        filtersController.toggleCategory('Estética Facial');
        _applyFiltersToDiscovery();
        break;
      case 'Injetáveis':
        filtersController.toggleCategory('Terapias Injetáveis');
        _applyFiltersToDiscovery();
        break;
    }
  }

  Widget _buildViewModeToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Obx(() {
            final count = controller.searchResultsCount;
            return Text(
              count > 0
                  ? '$count ${count == 1 ? 'resultado' : 'resultados'}'
                  : 'Nenhum resultado',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumGrey,
              ),
            );
          }),
          const Spacer(),
          Obx(
            () => ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              isSelected: [
                controller.currentViewMode == ViewMode.list,
                controller.currentViewMode == ViewMode.map,
              ],
              onPressed: (index) {
                controller.setViewMode(
                  index == 0 ? ViewMode.list : ViewMode.map,
                );
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.list),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.map),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (controller.isLoading) {
      return _buildLoadingState();
    }

    return controller.currentViewMode == ViewMode.list
        ? _buildListView()
        : _buildMapView();
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: controller.refreshDiscovery,
      child: PagedListView<int, Clinic>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Clinic>(
          itemBuilder: (context, clinic, index) => ClinicCard(
            clinic: clinic,
            onTap: () => _navigateToClinicDetails(clinic),
            onFavoritePressed: () => controller.toggleClinicFavorite(clinic.id),
          ),
          firstPageErrorIndicatorBuilder: (context) => _buildErrorState(),
          newPageErrorIndicatorBuilder: (context) => _buildErrorState(),
          firstPageProgressIndicatorBuilder: (context) => _buildLoadingState(),
          newPageProgressIndicatorBuilder: (context) =>
              _buildLoadingMoreState(),
          noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: MapViewScreen(
        clinics: controller.filteredClinics,
        onClinicTap: _navigateToClinicDetails,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Carregando clínicas...',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.mediumGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma clínica encontrada',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.mediumGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros ou busque por outro termo',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              controller.clearAllFilters();
              _searchController.clear();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Limpar Filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verifique sua conexão e tente novamente',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _pagingController.refresh();
              controller.refreshDiscovery();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  void _openFilters() {
    Get.to(() => const FiltersScreen(), transition: Transition.rightToLeft);
  }

  void _applyQuickFilter(String filterName) {
    switch (filterName) {
      case 'Próximo':
        // Apply location filter
        break;
      case 'Hoje':
        filtersController.setAvailabilityToday(true);
        _applyFiltersToDiscovery();
        break;
      case 'Até 100SG':
        filtersController.updatePriceRange(const RangeValues(0, 100));
        _applyFiltersToDiscovery();
        break;
      case '4★+':
        filtersController.updateMinimumRating(4.0);
        _applyFiltersToDiscovery();
        break;
      case 'Estética':
        filtersController.toggleCategory('Estética Facial');
        _applyFiltersToDiscovery();
        break;
      case 'Injetáveis':
        filtersController.toggleCategory('Terapias Injetáveis');
        _applyFiltersToDiscovery();
        break;
    }
  }

  void _applyFiltersToDiscovery() {
    controller.updateFilters(filtersController.tempFilters);

    Get.snackbar(
      'Filtro Aplicado',
      'Resultados atualizados',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _navigateToClinicDetails(Clinic clinic) {
    Get.to(
      () => ClinicDetailsScreen(clinic: clinic),
      transition: Transition.rightToLeft,
    );
  }
}
