import 'package:get/get.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/clinic_services/services/clinic_services_api.dart';

class ClinicsListController extends GetxController {
  final RxList<Clinic> clinics = <Clinic>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadClinics();
  }

  Future<void> loadClinics() async {
    try {
      isLoading.value = true;
      error.value = '';

      final loadedClinics = await ClinicServicesApi.getClinics();
      clinics.value = loadedClinics;
    } catch (e) {
      error.value = 'Erro ao carregar clínicas: $e';
      clinics.value = [];
    } finally {
      isLoading.value = false;
    }
  }
}

