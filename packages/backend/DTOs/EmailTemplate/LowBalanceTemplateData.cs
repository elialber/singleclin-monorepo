namespace SingleClin.API.DTOs.EmailTemplate
{
    /// <summary>
    /// Template data for low balance notification emails
    /// </summary>
    public class LowBalanceTemplateData
    {
        /// <summary>
        /// User's name
        /// </summary>
        public string UserName { get; set; } = string.Empty;

        /// <summary>
        /// Current balance of credits
        /// </summary>
        public int CurrentBalance { get; set; }

        /// <summary>
        /// Plan name
        /// </summary>
        public string PlanName { get; set; } = string.Empty;

        /// <summary>
        /// Clinic name
        /// </summary>
        public string ClinicName { get; set; } = string.Empty;

        /// <summary>
        /// Clinic address
        /// </summary>
        public string ClinicAddress { get; set; } = string.Empty;

        /// <summary>
        /// Clinic phone
        /// </summary>
        public string ClinicPhone { get; set; } = string.Empty;

        /// <summary>
        /// Clinic email
        /// </summary>
        public string ClinicEmail { get; set; } = string.Empty;

        /// <summary>
        /// Support phone number
        /// </summary>
        public string SupportPhone { get; set; } = string.Empty;

        /// <summary>
        /// Support email
        /// </summary>
        public string SupportEmail { get; set; } = string.Empty;

        /// <summary>
        /// URL to renew credits
        /// </summary>
        public string RenewUrl { get; set; } = string.Empty;

        /// <summary>
        /// URL to app
        /// </summary>
        public string AppUrl { get; set; } = string.Empty;

        /// <summary>
        /// URL to support
        /// </summary>
        public string SupportUrl { get; set; } = string.Empty;

        /// <summary>
        /// URL to manage notification preferences
        /// </summary>
        public string PreferencesUrl { get; set; } = string.Empty;

        /// <summary>
        /// URL to unsubscribe/manage preferences
        /// </summary>
        public string UnsubscribeUrl { get; set; } = string.Empty;

        /// <summary>
        /// Current year for copyright
        /// </summary>
        public int CurrentYear { get; set; } = DateTime.Now.Year;

        /// <summary>
        /// Whether to use plural form for credits
        /// </summary>
        public bool IsPlural => CurrentBalance != 1;

        /// <summary>
        /// User ID for tracking
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// Plan ID for tracking
        /// </summary>
        public Guid PlanId { get; set; }

        /// <summary>
        /// Creates template data from notification context
        /// </summary>
        /// <param name="userId">User ID</param>
        /// <param name="userName">User name</param>
        /// <param name="currentBalance">Current balance</param>
        /// <param name="planName">Plan name</param>
        /// <param name="planId">Plan ID</param>
        /// <returns>Populated template data</returns>
        public static LowBalanceTemplateData Create(
            Guid userId,
            string userName,
            int currentBalance,
            string planName,
            Guid planId)
        {
            return new LowBalanceTemplateData
            {
                UserId = userId,
                UserName = userName,
                CurrentBalance = currentBalance,
                PlanName = planName,
                PlanId = planId,
                ClinicName = "SingleClin",
                ClinicAddress = "Rua das Clínicas, 123 - Centro - São Paulo, SP",
                ClinicPhone = "(11) 3456-7890",
                ClinicEmail = "contato@singleclin.com",
                SupportPhone = "(11) 3456-7899",
                SupportEmail = "suporte@singleclin.com",
                RenewUrl = $"https://app.singleclin.com/plans/renew?userId={userId}&planId={planId}",
                AppUrl = "https://app.singleclin.com",
                SupportUrl = "https://app.singleclin.com/support",
                PreferencesUrl = $"https://app.singleclin.com/profile/notifications?userId={userId}",
                UnsubscribeUrl = $"https://app.singleclin.com/profile/notifications?userId={userId}",
                CurrentYear = DateTime.Now.Year
            };
        }
    }
}