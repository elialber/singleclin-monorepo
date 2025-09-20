namespace SingleClin.API.DTOs.EmailTemplate
{
    /// <summary>
    /// Template data for user confirmation emails
    /// </summary>
    public class UserConfirmationTemplateData
    {
        /// <summary>
        /// User's name
        /// </summary>
        public string UserName { get; set; } = string.Empty;

        /// <summary>
        /// User's email address
        /// </summary>
        public string UserEmail { get; set; } = string.Empty;

        /// <summary>
        /// User's password (for confirmation email)
        /// </summary>
        public string UserPassword { get; set; } = string.Empty;

        /// <summary>
        /// Name of the associated clinic (optional)
        /// </summary>
        public string? ClinicName { get; set; }

        /// <summary>
        /// Application URL for accessing the system
        /// </summary>
        public string AppUrl { get; set; } = "https://singleclin.com";

        /// <summary>
        /// Support phone number
        /// </summary>
        public string SupportPhone { get; set; } = "(11) 99999-9999";

        /// <summary>
        /// Support email address
        /// </summary>
        public string SupportEmail { get; set; } = "suporte@singleclin.com";

        /// <summary>
        /// Support URL for help documentation
        /// </summary>
        public string SupportUrl { get; set; } = "https://suporte.singleclin.com";

        /// <summary>
        /// URL for managing preferences
        /// </summary>
        public string PreferencesUrl { get; set; } = "https://singleclin.com/preferences";

        /// <summary>
        /// Creates a new instance with basic user information
        /// </summary>
        /// <param name="userName">User's name</param>
        /// <param name="userEmail">User's email</param>
        /// <param name="userPassword">User's password</param>
        /// <param name="clinicName">Optional clinic name</param>
        /// <returns>New UserConfirmationTemplateData instance</returns>
        public static UserConfirmationTemplateData Create(
            string userName,
            string userEmail,
            string userPassword,
            string? clinicName = null)
        {
            return new UserConfirmationTemplateData
            {
                UserName = userName,
                UserEmail = userEmail,
                UserPassword = userPassword,
                ClinicName = clinicName
            };
        }
    }
}