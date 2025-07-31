# SingleClin - User Management Integration Plan

## Backend Implementation Requirements

### 1. User Model Extensions
```csharp
// Add to User.cs model
public string FullName => $"{FirstName} {LastName}".Trim();
public bool IsEmailVerified { get; set; } = false;
public DateTime? EmailVerifiedAt { get; set; }
public string? ClinicId { get; set; }
public virtual Clinic? Clinic { get; set; }
```

### 2. DTOs Structure
```csharp
// UserResponseDto.cs
public class UserResponseDto
{
    public string Id { get; set; }
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string FullName { get; set; }
    public string Role { get; set; }
    public bool IsActive { get; set; }
    public bool IsEmailVerified { get; set; }
    public string? PhoneNumber { get; set; }
    public string? PhotoUrl { get; set; }
    public string? ClinicId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

// CreateUserDto.cs
public class CreateUserDto
{
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Role { get; set; }
    public string? PhoneNumber { get; set; }
    public string? ClinicId { get; set; }
    public string Password { get; set; }
}

// UpdateUserDto.cs
public class UpdateUserDto
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? PhoneNumber { get; set; }
    public bool? IsActive { get; set; }
    public string? Role { get; set; }
    public string? ClinicId { get; set; }
}

// UserFilterDto.cs
public class UserFilterDto : PagedRequestDto
{
    public string? Search { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
    public string? ClinicId { get; set; }
}
```

### 3. UserController Implementation
```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : BaseController
{
    private readonly IUserService _userService;
    
    [HttpGet]
    [AuthorizeRole(UserRole.Administrator, UserRole.ClinicOrigin)]
    public async Task<IActionResult> GetUsers([FromQuery] UserFilterDto filter)
    {
        // Implementation with search, filtering, pagination
    }
    
    [HttpGet("{id}")]
    [AuthorizeRole(UserRole.Administrator, UserRole.ClinicOrigin)]
    public async Task<IActionResult> GetUser(string id)
    {
        // Get single user with validation
    }
    
    [HttpPost]
    [AuthorizeRole(UserRole.Administrator)]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserDto dto)
    {
        // Create user with password hashing, role validation
    }
    
    [HttpPut("{id}")]
    [AuthorizeRole(UserRole.Administrator, UserRole.ClinicOrigin)]
    public async Task<IActionResult> UpdateUser(string id, [FromBody] UpdateUserDto dto)
    {
        // Update user with authorization checks
    }
    
    [HttpDelete("{id}")]
    [AuthorizeRole(UserRole.Administrator)]
    public async Task<IActionResult> DeleteUser(string id)
    {
        // Soft delete implementation
    }
    
    [HttpPost("{id}/reset-password")]
    [AuthorizeRole(UserRole.Administrator)]
    public async Task<IActionResult> ResetPassword(string id)
    {
        // Generate reset token and send email
    }
}
```

### 4. Service Layer Implementation
```csharp
public interface IUserService
{
    Task<PagedResultDto<UserResponseDto>> GetUsersAsync(UserFilterDto filter);
    Task<UserResponseDto> GetUserByIdAsync(string id);
    Task<UserResponseDto> CreateUserAsync(CreateUserDto dto);
    Task<UserResponseDto> UpdateUserAsync(string id, UpdateUserDto dto);
    Task DeleteUserAsync(string id);
    Task ResetPasswordAsync(string id);
    Task<bool> ValidateClinicAssignmentAsync(string userId, string clinicId);
}
```

## API Contract Alignment

### Response Format Standardization
```typescript
// Align backend response with frontend expectations
interface ApiResponse<T> {
  data: T;
  success: boolean;
  message?: string;
  errors?: string[];
}

interface PagedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
}
```

### Search Implementation
- Backend should search across: firstName, lastName, email, phoneNumber
- Use case-insensitive contains search
- Phone number search should ignore formatting

### Role-Based Access Control
- Administrator: Full CRUD on all users
- ClinicOrigin: Read/Update users in their clinic, no delete
- ClinicPartner: Read-only access to their clinic users
- Patient: No access to user management

## UI/UX Improvements

### 1. Enhanced User Experience
- **Bulk Operations**: Add checkboxes for bulk status changes, role updates
- **Advanced Filtering**: Add date range filters for createdAt
- **Export Functionality**: CSV/Excel export with current filters
- **Inline Editing**: Quick edit for status toggle without dialog
- **User Import**: Bulk user creation via CSV upload

### 2. Visual Enhancements
- **User Avatars**: Display user initials or photo in list
- **Status Indicators**: Visual timeline for last activity
- **Role Icons**: Add icons for each role type
- **Search Highlighting**: Highlight matched terms in results
- **Empty States**: Better messaging and actions for empty lists

### 3. Performance Optimizations
- **Virtual Scrolling**: For large user lists
- **Debounced Search**: Already implemented, optimize delay
- **Cached Filters**: Remember user's last filter preferences
- **Optimistic Updates**: Immediate UI feedback on actions

### 4. Additional Features
- **Activity Log**: Show user's recent actions
- **Login History**: Last login time and location
- **Session Management**: Force logout capability
- **2FA Status**: Show and manage 2FA settings
- **Email Templates**: Customizable password reset emails

## Mobile App Integration

### 1. User Profile Management
```dart
// Add to mobile app
class UserProfileService {
  Future<UserEntity> getCurrentUser();
  Future<UserEntity> updateProfile(UpdateProfileDto dto);
  Future<void> changePassword(ChangePasswordDto dto);
  Future<void> uploadProfilePhoto(File photo);
}
```

### 2. Clinic Staff Features
- View clinic users (read-only)
- Search patients by name/phone
- Quick patient info access during scanning

### 3. Synchronization
- Cache user data locally
- Sync profile changes when online
- Handle offline profile updates

## Architectural Improvements

### 1. Missing Features
- **Audit Trail**: Track all user modifications
- **Email Verification**: Implement verification flow
- **Password Policy**: Enforce strong passwords
- **Account Lockout**: After failed login attempts
- **User Impersonation**: Admin support feature
- **API Rate Limiting**: Per-user rate limits

### 2. Security Enhancements
- **Data Encryption**: Encrypt sensitive user data
- **GDPR Compliance**: Data export/deletion rights
- **Security Headers**: Implement OWASP recommendations
- **Input Sanitization**: Prevent XSS/SQL injection

### 3. Performance Optimizations
- **Database Indexing**: On email, role, clinicId
- **Query Optimization**: Eager load clinic data
- **Response Caching**: Cache user lists with ETags
- **Background Jobs**: Async email sending

### 4. Monitoring & Analytics
- **User Metrics**: Active users, role distribution
- **Usage Analytics**: Feature adoption tracking
- **Error Tracking**: User-specific error rates
- **Performance Monitoring**: API response times

## Implementation Priority

### Phase 1 (Critical - Week 1)
1. Create UserController with basic CRUD
2. Implement UserService with business logic
3. Add database migrations for missing fields
4. Update frontend to use real API
5. Implement authentication/authorization

### Phase 2 (Important - Week 2)
1. Add search and filtering
2. Implement password reset flow
3. Add email verification
4. Enhance error handling
5. Add audit logging

### Phase 3 (Enhancement - Week 3)
1. Implement bulk operations
2. Add export functionality
3. Enhance UI/UX features
4. Add activity tracking
5. Implement caching

### Phase 4 (Mobile - Week 4)
1. Add profile API endpoints
2. Implement mobile profile screen
3. Add clinic staff features
4. Implement offline sync
5. Add push notifications

## Testing Strategy

### Unit Tests
- UserService business logic
- Validation rules
- Search algorithms
- Permission checks

### Integration Tests
- API endpoint responses
- Database operations
- Email sending
- Authentication flow

### E2E Tests
- User creation workflow
- Search and filter
- Role-based access
- Password reset flow

### Performance Tests
- Large dataset handling
- Concurrent user updates
- Search performance
- API response times