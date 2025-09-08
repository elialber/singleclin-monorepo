import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../controllers/filters_controller.dart';
import '../models/filter_options.dart';

/// Advanced filters screen with mobile-optimized touch interactions
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({Key? key}) : super(key: key);

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen>
    with TickerProviderStateMixin {
  final FiltersController controller = Get.find<FiltersController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    controller.initializeTempFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicFilters(),
                _buildLocationAndDistance(),
                _buildAdvancedFilters(),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Filtros',
      showBackButton: true,
      actions: [
        TextButton(
          onPressed: controller.resetFilters,
          child: const Text('Limpar'),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.lightGrey),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.mediumGrey,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        tabs: const [
          Tab(
            icon: Icon(Icons.tune),
            text: 'Básico',
          ),
          Tab(
            icon: Icon(Icons.location_on),
            text: 'Localização',
          ),
          Tab(
            icon: Icon(Icons.settings),
            text: 'Avançado',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickFilterPresets(),
          const SizedBox(height: 24),
          _buildPriceRangeFilter(),
          const SizedBox(height: 24),
          _buildRatingFilter(),
          const SizedBox(height: 24),
          _buildCategoriesFilter(),
          const SizedBox(height: 24),
          _buildAvailabilityFilter(),
        ],
      ),
    );
  }

  Widget _buildLocationAndDistance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentLocationCard(),
          const SizedBox(height: 24),
          _buildDistanceFilter(),
          const SizedBox(height: 24),
          _buildLocationOptions(),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClinicOptions(),
          const SizedBox(height: 24),
          _buildAmenitiesFilter(),
          const SizedBox(height: 24),
          _buildSortOptions(),
        ],
      ),
    );
  }

  Widget _buildQuickFilterPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtros Rápidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: QuickFilters.presets.map((preset) {
            return ActionChip(
              label: Text(preset.key),
              onPressed: () => controller.applyQuickFilter(preset.key),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.lightGrey),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Obx(() => _buildFilterSection(
          title: 'Faixa de Preço (SG)',
          subtitle: controller.priceRangeText,
          child: Column(
            children: [
              RangeSlider(
                values: controller.priceRangeValues,
                min: 0,
                max: 500,
                divisions: 50,
                labels: RangeLabels(
                  '${controller.priceRangeValues.start.round()}SG',
                  '${controller.priceRangeValues.end.round()}SG',
                ),
                onChanged: controller.updatePriceRange,
              ),
              const SizedBox(height: 8),
              Row(
                children: PriceRangeFilter.commonRanges.map((range) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        onPressed: () {
                          controller.updatePriceRange(RangeValues(
                            range.minPrice?.toDouble() ?? 0,
                            range.maxPrice?.toDouble() ?? 500,
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          range.displayText,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ));
  }

  Widget _buildRatingFilter() {
    return Obx(() => _buildFilterSection(
          title: 'Avaliação Mínima',
          subtitle: controller.ratingText,
          child: Column(
            children: [
              Slider(
                value: controller.minimumRating,
                min: 0,
                max: 5,
                divisions: 10,
                label: '${controller.minimumRating.toStringAsFixed(1)}★',
                onChanged: controller.updateMinimumRating,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: RatingFilter.commonFilters.map((filter) {
                  return OutlinedButton(
                    onPressed: () {
                      controller.updateMinimumRating(
                        filter.minimumRating ?? 0,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      filter.displayText,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ));
  }

  Widget _buildCategoriesFilter() {
    return Obx(() => _buildFilterSection(
          title: 'Categorias',
          subtitle: controller.selectedCategoriesText,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: controller.selectAllCategories,
                    child: const Text('Selecionar Todas'),
                  ),
                  TextButton(
                    onPressed: controller.clearAllCategories,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryFilter.availableCategories.map((category) {
                  final isSelected = controller.tempFilters.categories.selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => controller.toggleCategory(category),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ],
          ),
        ));
  }

  Widget _buildAvailabilityFilter() {
    return Obx(() => _buildFilterSection(
          title: 'Disponibilidade',
          subtitle: controller.tempFilters.availability.displayText,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Disponível hoje'),
                value: controller.tempFilters.availability.todayOnly,
                onChanged: controller.setAvailabilityToday,
                activeColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text('Disponível esta semana'),
                value: controller.tempFilters.availability.thisWeekOnly,
                onChanged: controller.setAvailabilityThisWeek,
                activeColor: AppColors.primary,
              ),
              ListTile(
                title: const Text('Data específica'),
                subtitle: controller.tempFilters.availability.specificDate != null
                    ? Text('${controller.tempFilters.availability.specificDate!.day}/${controller.tempFilters.availability.specificDate!.month}')
                    : const Text('Nenhuma data selecionada'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectSpecificDate,
              ),
            ],
          ),
        ));
  }

  Widget _buildCurrentLocationCard() {
    return Obx(() => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: controller.tempFilters.location != null
                      ? AppColors.primary
                      : AppColors.mediumGrey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Localização Atual',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        controller.tempFilters.location?.displayText ?? 'Não definida',
                        style: const TextStyle(
                          color: AppColors.mediumGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                controller.isLocationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: controller.updateLocationFilter,
                        icon: const Icon(Icons.refresh),
                      ),
              ],
            ),
          ),
        ));
  }

  Widget _buildDistanceFilter() {
    return Obx(() => _buildFilterSection(
          title: 'Distância Máxima',
          subtitle: controller.distanceText,
          child: Column(
            children: [
              Slider(
                value: controller.distanceValue,
                min: 0.5,
                max: 50,
                divisions: 50,
                label: controller.distanceText,
                onChanged: controller.updateDistance,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: DistanceFilter.commonDistances.map((distance) {
                  return OutlinedButton(
                    onPressed: () => controller.updateDistance(distance),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      distance < 1
                          ? '${(distance * 1000).toInt()}m'
                          : '${distance.toStringAsFixed(1)}km',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ));
  }

  Widget _buildLocationOptions() {
    return _buildFilterSection(
      title: 'Opções de Localização',
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Buscar endereço'),
            subtitle: const Text('Digite um endereço específico'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _searchAddress,
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Selecionar no mapa'),
            subtitle: const Text('Escolha uma localização no mapa'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectOnMap,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicOptions() {
    return Obx(() => _buildFilterSection(
          title: 'Opções da Clínica',
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Apenas clínicas verificadas'),
                subtitle: const Text('Clínicas com selo de verificação'),
                value: controller.tempFilters.onlyVerifiedClinics,
                onChanged: controller.toggleVerifiedClinicsOnly,
                activeColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text('Aceita créditos SG'),
                subtitle: const Text('Clínicas que aceitam pagamento com SG'),
                value: controller.tempFilters.onlyAcceptingSG,
                onChanged: controller.toggleAcceptingSGOnly,
                activeColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text('Com promoções'),
                subtitle: const Text('Clínicas com ofertas especiais'),
                value: controller.tempFilters.onlyWithPromotion,
                onChanged: controller.togglePromotionOnly,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ));
  }

  Widget _buildAmenitiesFilter() {
    return Obx(() => _buildFilterSection(
          title: 'Comodidades',
          subtitle: controller.selectedAmenitiesText,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.clearAllAmenities,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.availableAmenities.map((amenity) {
                  final isSelected = controller.tempFilters.amenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (_) => controller.toggleAmenity(amenity),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ],
          ),
        ));
  }

  Widget _buildSortOptions() {
    return Obx(() => _buildFilterSection(
          title: 'Ordenar por',
          child: Column(
            children: SortOption.values.map((option) {
              return RadioListTile<SortOption>(
                title: Text(option.displayName),
                value: option,
                groupValue: controller.tempFilters.sortBy,
                onChanged: (value) {
                  if (value != null) {
                    controller.updateSortOption(value);
                  }
                },
                activeColor: AppColors.primary,
              );
            }).toList(),
          ),
        ));
  }

  Widget _buildFilterSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Flexible(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.lightGrey),
        ),
      ),
      child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.activeFiltersCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${controller.activeFiltersCount} ${controller.activeFiltersCount == 1 ? 'filtro ativo' : 'filtros ativos'}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.hasChanges
                          ? controller.cancelFilters
                          : () => Get.back(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: controller.applyFilters,
                      child: const Text('Aplicar Filtros'),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }

  void _selectSpecificDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.tempFilters.availability.specificDate ?? 
                  DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (date != null) {
      controller.setSpecificDateAvailability(date, null);
    }
  }

  void _searchAddress() {
    // This would open a search interface for addresses
    Get.snackbar(
      'Em desenvolvimento',
      'Busca de endereço será implementada em breve',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _selectOnMap() {
    // This would open a map picker
    Get.snackbar(
      'Em desenvolvimento',
      'Seleção no mapa será implementada em breve',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}