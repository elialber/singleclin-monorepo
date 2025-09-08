# Discovery Module - SingleClin Mobile App

## Overview

The Discovery Module (Module 2) is a comprehensive clinic discovery and appointment booking system optimized for mobile devices. It provides users with powerful search capabilities, interactive maps, advanced filtering, and seamless appointment scheduling integrated with the SG credits system.

## Features

### 🔍 Discovery & Search
- **Dual View Mode**: Toggle between list and map views
- **Intelligent Search**: Real-time search with debouncing and autocomplete
- **Advanced Filtering**: Location, price range, ratings, categories, and more
- **Quick Filters**: Pre-configured filter sets for common use cases
- **Geolocation Integration**: Location-based clinic discovery

### 🗺️ Interactive Maps
- **Google Maps Integration**: Custom markers and clustering
- **Touch-Optimized Controls**: Zoom, pan, and marker interactions
- **Clinic Markers**: Custom markers with pricing and status
- **Bottom Sheet Details**: Clinic information on marker tap
- **Directions Integration**: Route planning to clinics

### 📱 Mobile-First Design
- **Touch-Friendly Interface**: 44px+ touch targets
- **Responsive Layout**: Adapts from 320px to tablet sizes
- **Smooth Animations**: Hero transitions and micro-interactions
- **Performance Optimized**: Lazy loading and efficient caching
- **Offline Support**: Basic functionality without internet

### 💳 SG Credits Integration
- **Real-time Cost Display**: Prices shown in SG credits
- **Affordability Indicators**: Visual cues for affordable services
- **Package Deals**: Multi-session discounts and promotions
- **Credit Balance Checks**: Prevent overbooking beyond available credits

## Architecture

### File Structure
```
lib/features/discovery/
├── controllers/
│   ├── discovery_controller.dart     # Main search & filtering logic
│   ├── map_controller.dart          # Google Maps management
│   ├── filters_controller.dart      # Advanced filtering system
│   ├── booking_controller.dart      # Appointment scheduling
│   └── discovery_binding.dart       # Dependency injection
├── models/
│   ├── clinic.dart                  # Clinic data model
│   ├── service.dart                 # Medical service model
│   ├── booking.dart                 # Appointment model
│   └── filter_options.dart          # Filter configuration
├── screens/
│   ├── discovery_screen.dart        # Main discovery interface
│   ├── map_view_screen.dart         # Interactive map view
│   ├── filters_screen.dart          # Advanced filtering UI
│   ├── clinic_details_screen.dart   # Clinic information & gallery
│   └── booking_screen.dart          # Step-by-step appointment booking
└── widgets/
    ├── clinic_card.dart             # Clinic list item
    ├── service_card.dart            # Service display component
    └── README.md                    # This documentation
```

### Key Controllers

#### DiscoveryController
The main controller managing clinic search and discovery:
- **Search Management**: Debounced search with caching
- **Filter Application**: Reactive filtering system
- **Pagination**: Infinite scroll with performance optimization
- **Location Services**: GPS integration and distance calculation

```dart
final controller = Get.find<DiscoveryController>();
controller.updateSearchQuery('botox');
controller.applyQuickFilter(QuickFilters.nearbyToday);
```

#### MapController
Specialized controller for Google Maps integration:
- **Custom Markers**: Clinic-specific markers with pricing
- **Clustering**: Automatic marker grouping for performance
- **User Location**: Real-time location tracking
- **Camera Control**: Smooth map navigation and animations

```dart
final mapController = Get.find<MapController>();
await mapController.animateToLocation(LatLng(-23.5505, -46.6333), 14.0);
mapController.toggleClustering();
```

#### FiltersController
Advanced filtering system with mobile-optimized UI:
- **Real-time Updates**: Reactive filter application
- **Quick Presets**: Common filter combinations
- **Location Integration**: GPS-based distance filtering
- **State Management**: Temporary vs applied filters

```dart
final filtersController = Get.find<FiltersController>();
filtersController.updatePriceRange(RangeValues(0, 100));
filtersController.toggleCategory('Estética Facial');
filtersController.applyFilters();
```

#### BookingController
Comprehensive appointment scheduling system:
- **Step-by-Step Booking**: 4-step booking process
- **Calendar Integration**: Available dates and time slots
- **Service Selection**: Package deals and pricing
- **Reminder Settings**: Customizable notifications

```dart
final bookingController = Get.find<BookingController>();
bookingController.initializeBooking(clinic, service);
bookingController.selectDate(DateTime.now().add(Duration(days: 1)));
await bookingController.createBooking();
```

## Data Models

### Clinic Model
Comprehensive clinic information with location and services:

```dart
class Clinic {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<Service> services;
  final double rating;
  final bool isVerified;
  // ... additional properties
}
```

### Service Model
Medical/aesthetic service with pricing and availability:

```dart
class Service {
  final String id;
  final String name;
  final int priceInSG;
  final int durationMinutes;
  final ServicePricing? pricing;
  final List<ServiceAvailability> availability;
  // ... additional properties
}
```

### Booking Model
Complete appointment information:

```dart
class Booking {
  final String id;
  final String clinicId;
  final String serviceId;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final BookingStatus status;
  final int totalCostSG;
  // ... additional properties
}
```

## Mobile Optimization

### Performance Features
- **Lazy Loading**: Services and images loaded on demand
- **Search Debouncing**: 500ms delay to reduce API calls
- **Cache Management**: 5-minute cache validity for search results
- **Efficient Rendering**: RecyclerView-style list optimization

### Touch Interactions
- **Minimum Touch Targets**: 44px × 44px for all interactive elements
- **Gesture Support**: Swipe, pinch-to-zoom, pull-to-refresh
- **Haptic Feedback**: Tactile responses for key interactions
- **Visual Feedback**: Loading states and progress indicators

### Responsive Design
- **Breakpoint Support**: 320px (small), 375px (medium), 768px (tablet)
- **Flexible Layouts**: Constraint-based layouts for all screen sizes
- **Adaptive Typography**: Relative font sizes with minimum readability
- **Safe Area Handling**: Notch and gesture area considerations

## Integration Points

### Navigation
```dart
// Navigate to discovery
Get.toNamed(AppRoutes.discovery);

// Open clinic details
Get.to(() => ClinicDetailsScreen(clinic: clinic));

// Start booking process
Get.to(() => const BookingScreen());
```

### SG Credits Integration
```dart
// Check affordability
final isAffordable = userCredits >= service.priceInSG;

// Display cost
SgCostChip(
  cost: service.priceInSG,
  isAffordable: isAffordable,
)
```

### Location Services
```dart
// Get user location
final position = await LocationService.getCurrentPosition();

// Calculate distance
final distance = Geolocator.distanceBetween(
  userLat, userLng, clinicLat, clinicLng
) / 1000; // Convert to km
```

## API Integration

### Expected Endpoints
```
GET /clinics/search?q=query&lat=lat&lng=lng&filters=...
GET /clinics/:id
GET /clinics/:id/services/:serviceId/availability?date=date
GET /clinics/:id/services/:serviceId/timeslots?date=date
POST /bookings
```

### Response Formats
```json
{
  "clinics": [
    {
      "id": "clinic-id",
      "name": "Clinic Name",
      "latitude": -23.5505,
      "longitude": -46.6333,
      "services": [...],
      "rating": 4.5,
      "reviewCount": 127
    }
  ],
  "totalCount": 42,
  "hasMore": true
}
```

## Testing Strategy

### Unit Tests
- Controller logic validation
- Model serialization/deserialization
- Filter application accuracy
- Booking flow validation

### Widget Tests
- Screen rendering
- User interaction handling
- State management verification
- Animation behavior

### Integration Tests
- End-to-end booking flow
- Search and filter combinations
- Map interaction scenarios
- API integration validation

## Performance Metrics

### Target Performance
- **Initial Load**: < 2 seconds on 3G
- **Search Response**: < 500ms for cached results
- **Map Rendering**: < 1 second for 50+ markers
- **Booking Flow**: < 30 seconds completion time

### Memory Usage
- **Base Memory**: < 50MB for discovery module
- **Peak Usage**: < 100MB with full image cache
- **Cache Size**: < 20MB for search results

## Accessibility

### Features
- **Screen Reader Support**: Semantic labels and descriptions
- **High Contrast**: Color-blind friendly design
- **Touch Accessibility**: Large touch targets and gesture alternatives
- **Text Scaling**: Supports system text size preferences

### Implementation
```dart
Semantics(
  label: 'Book appointment at ${clinic.name}',
  hint: 'Double tap to open booking screen',
  child: ElevatedButton(...),
)
```

## Future Enhancements

### Planned Features
- **AR Clinic Finder**: Camera overlay with clinic directions
- **Voice Search**: Speech-to-text search integration
- **Smart Recommendations**: AI-powered clinic suggestions
- **Social Features**: Reviews and clinic check-ins
- **Offline Mode**: Cached clinic data for offline viewing

### Technical Improvements
- **GraphQL Migration**: More efficient data fetching
- **State Persistence**: Cross-session filter preferences
- **Push Notifications**: Location-based clinic recommendations
- **Analytics Integration**: User behavior tracking

## Troubleshooting

### Common Issues

#### Search Not Working
```dart
// Check network connectivity
if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
  // Handle offline state
}

// Verify API service initialization
final apiService = Get.find<ApiService>();
```

#### Map Not Loading
```dart
// Verify Google Maps API key
const String googleMapsApiKey = 'YOUR_API_KEY';

// Check location permissions
final permission = await Geolocator.checkPermission();
```

#### Booking Errors
```dart
// Validate booking data
if (!controller.canProceedToNextStep) {
  // Handle validation errors
}

// Check SG credit balance
if (userCredits < service.priceInSG) {
  // Show insufficient credits message
}
```

## Support

For technical support or feature requests related to the Discovery module:

1. **Documentation**: Check this README and inline code comments
2. **Code Review**: Examine controller implementations for usage examples
3. **Testing**: Run unit and widget tests for module validation
4. **Debugging**: Use Flutter Inspector and GetX debugging tools

---

*This documentation covers the complete Discovery Module implementation. For questions about other modules or general app architecture, refer to the main project documentation.*