"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationType = exports.UserPlanStatus = exports.TransactionStatus = exports.ClinicType = exports.UserRole = void 0;
var UserRole;
(function (UserRole) {
    UserRole["PATIENT"] = "patient";
    UserRole["CLINIC"] = "clinic";
    UserRole["ADMIN"] = "admin";
})(UserRole || (exports.UserRole = UserRole = {}));
var ClinicType;
(function (ClinicType) {
    ClinicType["ORIGIN"] = "origin";
    ClinicType["PARTNER"] = "partner";
})(ClinicType || (exports.ClinicType = ClinicType = {}));
var TransactionStatus;
(function (TransactionStatus) {
    TransactionStatus["PENDING"] = "pending";
    TransactionStatus["COMPLETED"] = "completed";
    TransactionStatus["FAILED"] = "failed";
    TransactionStatus["CANCELLED"] = "cancelled";
})(TransactionStatus || (exports.TransactionStatus = TransactionStatus = {}));
var UserPlanStatus;
(function (UserPlanStatus) {
    UserPlanStatus["ACTIVE"] = "active";
    UserPlanStatus["EXPIRED"] = "expired";
    UserPlanStatus["CANCELLED"] = "cancelled";
    UserPlanStatus["SUSPENDED"] = "suspended";
})(UserPlanStatus || (exports.UserPlanStatus = UserPlanStatus = {}));
var NotificationType;
(function (NotificationType) {
    NotificationType["LOW_CREDITS"] = "low_credits";
    NotificationType["PLAN_EXPIRED"] = "plan_expired";
    NotificationType["TRANSACTION_SUCCESS"] = "transaction_success";
    NotificationType["TRANSACTION_FAILED"] = "transaction_failed";
    NotificationType["SYSTEM_MAINTENANCE"] = "system_maintenance";
})(NotificationType || (exports.NotificationType = NotificationType = {}));
//# sourceMappingURL=index.js.map