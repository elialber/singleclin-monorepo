import 'package:get/get.dart';
import 'package:singleclin_mobile/features/engagement/controllers/community_controller.dart';
import 'package:singleclin_mobile/features/engagement/controllers/faq_controller.dart';
import 'package:singleclin_mobile/features/engagement/controllers/feedback_controller.dart';
import 'package:singleclin_mobile/features/engagement/controllers/reviews_controller.dart';
import 'package:singleclin_mobile/features/engagement/controllers/support_controller.dart';
import 'package:singleclin_mobile/features/engagement/controllers/trust_center_controller.dart';
import 'package:singleclin_mobile/features/engagement/controllers/write_review_controller.dart';

/// Binding for all engagement module controllers
class EngagementBinding extends Bindings {
  @override
  void dependencies() {
    // Core engagement controllers
    Get.lazyPut(ReviewsController.new);
    Get.lazyPut(WriteReviewController.new);
    Get.lazyPut(SupportController.new);
    Get.lazyPut(FaqController.new);
    Get.lazyPut(CommunityController.new);
    Get.lazyPut(FeedbackController.new);
    Get.lazyPut(TrustCenterController.new);
  }
}

/// Individual bindings for specific screens

class ReviewsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ReviewsController.new);
  }
}

class WriteReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(WriteReviewController.new);
  }
}

class SupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(SupportController.new);
  }
}

class FaqBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(FaqController.new);
  }
}

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(CommunityController.new);
  }
}

class FeedbackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(FeedbackController.new);
  }
}

class TrustCenterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(TrustCenterController.new);
  }
}
