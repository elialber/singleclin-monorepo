import 'package:get/get.dart';
import '../controllers/reviews_controller.dart';
import '../controllers/write_review_controller.dart';
import '../controllers/support_controller.dart';
import '../controllers/faq_controller.dart';
import '../controllers/community_controller.dart';
import '../controllers/feedback_controller.dart';
import '../controllers/trust_center_controller.dart';

/// Binding for all engagement module controllers
class EngagementBinding extends Bindings {
  @override
  void dependencies() {
    // Core engagement controllers
    Get.lazyPut(() => ReviewsController());
    Get.lazyPut(() => WriteReviewController());
    Get.lazyPut(() => SupportController());
    Get.lazyPut(() => FaqController());
    Get.lazyPut(() => CommunityController());
    Get.lazyPut(() => FeedbackController());
    Get.lazyPut(() => TrustCenterController());
  }
}

/// Individual bindings for specific screens

class ReviewsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ReviewsController());
  }
}

class WriteReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WriteReviewController());
  }
}

class SupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SupportController());
  }
}

class FaqBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FaqController());
  }
}

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CommunityController());
  }
}

class FeedbackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FeedbackController());
  }
}

class TrustCenterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TrustCenterController());
  }
}