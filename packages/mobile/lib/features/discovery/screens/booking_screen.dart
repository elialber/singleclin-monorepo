import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/sg_credit_widget.dart';
import '../controllers/booking_controller.dart';
import '../models/booking.dart';
import '../widgets/service_card.dart';

/// Booking screen with step-by-step appointment scheduling
class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with TickerProviderStateMixin {
  final BookingController controller = Get.find<BookingController>();
  late AnimationController _stepAnimationController;
  late Animation<double> _stepAnimation;

  @override
  void initState() {
    super.initState();
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stepAnimationController, curve: Curves.easeInOut),
    );
    _stepAnimationController.forward();
  }

  @override
  void dispose() {
    _stepAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: FadeTransition(
                opacity: _stepAnimation,
                child: Obx(() => _buildStepContent()),
              ),
            ),
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return Obx(() => CustomAppBar(
          title: controller.stepTitle,
          showBackButton: true,
          onBackPressed: _handleBackPress,
        ));
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Obx(() => Row(
            children: List.generate(BookingController.maxSteps, (index) {
              final isActive = index == controller.currentStep;
              final isCompleted = index < controller.currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < BookingController.maxSteps - 1 ? 8 : 0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.primary
                              : isActive
                                  ? AppColors.primary
                                  : AppColors.lightGrey,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : AppColors.mediumGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStepLabel(index),
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? AppColors.primary : AppColors.mediumGrey,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          )),
    );
  }

  Widget _buildStepContent() {
    switch (controller.currentStep) {
      case 0:
        return _buildServiceSelectionStep();
      case 1:
        return _buildDateSelectionStep();
      case 2:
        return _buildTimeSelectionStep();
      case 3:
        return _buildConfirmationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildServiceSelectionStep() {
    final clinic = controller.selectedClinic;
    if (clinic == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Escolha o serviço',
            'Selecione o procedimento que deseja agendar',
          ),
          const SizedBox(height: 16),
          ...clinic.services.map((service) => Obx(() {
            final isSelected = controller.selectedService?.id == service.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.lightGrey,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ServiceCard(
                service: service,
                compact: true,
                onTap: () => controller.selectService(service),
              ),
            );
          })).toList(),
        ],
      ),
    );
  }

  Widget _buildDateSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Escolha a data',
            'Selecione um dia disponível para seu agendamento',
          ),
          const SizedBox(height: 16),
          _buildCalendar(),
          if (controller.selectedDate != null) ...[
            const SizedBox(height: 16),
            _buildSelectedDateInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Escolha o horário',
            'Selecione um horário disponível',
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoadingTimeSlots) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.availableTimeSlots.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 64,
                      color: AppColors.mediumGrey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum horário disponível',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tente selecionar outra data',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return _buildTimeSlotGrid();
          }),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Confirmar agendamento',
            'Revise os detalhes antes de confirmar',
          ),
          const SizedBox(height: 16),
          _buildBookingSummary(),
          const SizedBox(height: 24),
          _buildNotesSection(),
          const SizedBox(height: 24),
          _buildReminderSettings(),
          const SizedBox(height: 24),
          _buildTermsAndConditions(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() => TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: controller.focusedDay,
              selectedDayPredicate: (day) {
                return controller.selectedDate != null &&
                    isSameDay(controller.selectedDate!, day);
              },
              calendarFormat: controller.calendarFormat,
              availableGestures: AvailableGestures.all,
              onDaySelected: (selectedDay, focusedDay) {
                if (controller.isDateAvailable(selectedDay)) {
                  controller.selectDate(selectedDay);
                  controller.updateFocusedDay(focusedDay);
                  _stepAnimationController.forward();
                }
              },
              onFormatChanged: (format) {
                controller.toggleCalendarFormat();
              },
              enabledDayPredicate: controller.isDateAvailable,
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                disabledDecoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Colors.white,
                ),
              ),
            )),
      ),
    );
  }

  Widget _buildSelectedDateInfo() {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Data selecionada: ${controller.selectedDate!.day}/${controller.selectedDate!.month}/${controller.selectedDate!.year}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: controller.availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = controller.availableTimeSlots[index];
        final isSelected = controller.selectedTimeSlot?.time == timeSlot.time;

        return Obx(() => Material(
              color: timeSlot.isAvailable
                  ? (isSelected ? AppColors.primary : Colors.white)
                  : AppColors.lightGrey,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: timeSlot.isAvailable
                    ? () => controller.selectTimeSlot(timeSlot)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : timeSlot.isAvailable
                              ? AppColors.lightGrey
                              : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      timeSlot.formattedTime,
                      style: TextStyle(
                        color: timeSlot.isAvailable
                            ? (isSelected ? Colors.white : AppColors.darkGrey)
                            : AppColors.mediumGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ));
      },
    );
  }

  Widget _buildBookingSummary() {
    final summary = controller.getBookingSummary();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo do Agendamento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Clínica', summary['clinic']),
            _buildSummaryRow('Serviço', summary['service']),
            _buildSummaryRow('Data', summary['date']),
            _buildSummaryRow('Horário', summary['time']),
            _buildSummaryRow('Duração', summary['duration']),
            if (summary['professional'] != null)
              _buildSummaryRow('Profissional', summary['professional']),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SgCostChip(
                  cost: controller.totalCostSG,
                  isAffordable: true, // We'll add credit check later
                  fontSize: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mediumGrey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observações (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Adicione qualquer informação relevante...',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.updateNotes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lembretes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Column(
                  children: [
                    SwitchListTile(
                      title: const Text('1 dia antes'),
                      subtitle: const Text('Receber lembrete 24h antes'),
                      value: controller.bookingReminders.oneDayBefore,
                      onChanged: (value) {
                        controller.updateReminders(BookingReminders(
                          oneDayBefore: value,
                          oneHourBefore: controller.bookingReminders.oneHourBefore,
                          thirtyMinutesBefore: controller.bookingReminders.thirtyMinutesBefore,
                        ));
                      },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('1 hora antes'),
                      subtitle: const Text('Receber lembrete 1h antes'),
                      value: controller.bookingReminders.oneHourBefore,
                      onChanged: (value) {
                        controller.updateReminders(BookingReminders(
                          oneDayBefore: controller.bookingReminders.oneDayBefore,
                          oneHourBefore: value,
                          thirtyMinutesBefore: controller.bookingReminders.thirtyMinutesBefore,
                        ));
                      },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Obx(() => CheckboxListTile(
          title: const Text('Aceito os termos e condições'),
          subtitle: const Text('Li e concordo com as políticas de agendamento'),
          value: controller.agreedToTerms,
          onChanged: (value) => controller.toggleTermsAgreement(value ?? false),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ));
  }

  Widget _buildBottomNavigationBar() {
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
      child: Obx(() => Row(
            children: [
              if (controller.canGoBack)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleBackPress,
                    child: const Text('Voltar'),
                  ),
                ),
              if (controller.canGoBack) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: controller.currentStep == BookingController.maxSteps - 1
                    ? ElevatedButton(
                        onPressed: controller.canProceedToNextStep && !controller.isCreatingBooking
                            ? _confirmBooking
                            : null,
                        child: controller.isCreatingBooking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirmar Agendamento'),
                      )
                    : ElevatedButton(
                        onPressed: controller.canProceedToNextStep ? _handleNextPress : null,
                        child: const Text('Próximo'),
                      ),
              ),
            ],
          )),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.mediumGrey,
          ),
        ),
      ],
    );
  }

  String _getStepLabel(int index) {
    switch (index) {
      case 0:
        return 'Serviço';
      case 1:
        return 'Data';
      case 2:
        return 'Horário';
      case 3:
        return 'Confirmar';
      default:
        return '';
    }
  }

  Future<bool> _onWillPop() async {
    if (controller.currentStep > 0) {
      _handleBackPress();
      return false;
    }
    return await _showCancelDialog();
  }

  void _handleBackPress() {
    if (controller.canGoBack) {
      controller.previousStep();
      _stepAnimationController.reset();
      _stepAnimationController.forward();
    }
  }

  void _handleNextPress() {
    if (controller.canProceedToNextStep) {
      controller.nextStep();
      _stepAnimationController.reset();
      _stepAnimationController.forward();
    }
  }

  Future<void> _confirmBooking() async {
    final success = await controller.createBooking();
    if (success) {
      // The controller handles success dialog and navigation
    }
  }

  Future<bool> _showCancelDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar agendamento'),
        content: const Text('Tem certeza de que deseja cancelar este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}