# Gulf Lands Analytics SDK Integration Guide

## Overview

The Gulf Lands Analytics SDK is a JavaScript library for tracking user interactions and events across the Gulf Lands platform. It provides reliable event tracking with batching, retry mechanisms, and privacy-safe pseudonymization.

## Features

- **Event Tracking**: Tracks predefined events (page_view, filter_applied, listing_opened, favorite_toggled, contact_clicked)
- **Batching**: Sends events in batches to reduce network overhead
- **Retry Logic**: Implements exponential backoff for failed requests
- **Persistence**: Stores events locally when offline
- **Privacy**: Uses pseudonymized user and session IDs
- **Cross-Platform**: Works in browsers and can be adapted for Flutter web

## Installation

### For Marketing Site

1. Include the SDK script in your HTML:

```html
<script src="analytics-sdk.js"></script>
```

### For Flutter Web

1. Add the SDK file to your `web/` directory
2. Include it in your `index.html`:

```html
<script src="analytics-sdk.js"></script>
```

3. Or, if using a CDN (when available):

```html
<script src="https://cdn.gulflands.com/analytics-sdk.js"></script>
```

## Configuration

Create an instance of the AnalyticsSDK with optional configuration:

```javascript
const analytics = new AnalyticsSDK({
    endpoint: 'https://api.gulflands.com/v1/analytics/events', // Backend endpoint
    batchSize: 10,        // Number of events to batch before sending
    maxRetries: 5,        // Maximum retry attempts
    backoffMultiplier: 2, // Exponential backoff multiplier
    initialBackoff: 1000, // Initial retry delay in ms
    flushInterval: 30000  // Auto-flush interval in ms
});
```

## Event Tracking

### Page View

Track when a user views a page:

```javascript
analytics.trackPageView({
    page_title: 'Home Page',
    category: 'landing'
});
```

### Filter Applied

Track when a user applies filters:

```javascript
analytics.trackFilterApplied({
    filters: {
        country: 'Saudi Arabia',
        min_price: 1000000,
        max_price: 5000000
    }
});
```

### Listing Opened

Track when a user opens a listing:

```javascript
analytics.trackListingOpened('listing_123', {
    source: 'search_results',
    position: 5
});
```

### Favorite Toggled

Track when a user favorites/unfavorites a listing:

```javascript
analytics.trackFavoriteToggled('listing_123', true, {
    source: 'listing_detail'
});
```

### Contact Clicked

Track when a user clicks contact information:

```javascript
analytics.trackContactClicked('listing_123', 'phone', {
    source: 'listing_detail'
});
```

## Integration Examples

### Marketing Site Integration

Replace the existing analytics code in `script.js`:

```javascript
// Remove old Analytics class and replace with SDK
const analytics = new AnalyticsSDK({
    endpoint: '/api/analytics/events' // Adjust endpoint as needed
});

// Track page views
analytics.trackPageView({
    page: window.location.pathname
});

// Track CTA clicks
document.querySelectorAll('.cta-button').forEach(button => {
    button.addEventListener('click', (e) => {
        analytics.trackEvent('cta_click', { // Note: using generic track for custom events
            button_text: e.target.textContent,
            button_location: e.target.closest('section')?.id || 'unknown'
        });
    });
});
```

### Flutter Web Integration

In your Flutter web app, you can use the SDK via JavaScript interop:

```dart
import 'dart:js' as js;

// Initialize SDK
void initAnalytics() {
  js.context.callMethod('eval', ['''
    window.analytics = new AnalyticsSDK({
      endpoint: 'https://api.gulflands.com/v1/analytics/events'
    });
  ''']);
}

// Track events
void trackPageView(String page) {
  js.context.callMethod('analytics.trackPageView', [
    js.JsObject.jsify({'page': page})
  ]);
}

void trackListingOpened(String listingId) {
  js.context.callMethod('analytics.trackListingOpened', [listingId]);
}
```

## Backend Endpoint

The SDK sends POST requests to the configured endpoint with the following format:

```json
{
  "events": [
    {
      "event": "page_view",
      "properties": {
        "timestamp": "2023-12-01T10:00:00.000Z",
        "session_id": "abc123def456",
        "user_id": "user789xyz",
        "user_agent": "Mozilla/5.0...",
        "url": "https://gulflands.com/listings",
        "page": "/listings",
        "referrer": "https://google.com"
      }
    }
  ]
}
```

## Privacy and Compliance

- User IDs are generated using a hash of browser fingerprint data
- Session IDs are randomly generated for each session
- No personally identifiable information is collected
- Events are batched and sent securely over HTTPS

## Error Handling and Reliability

- Failed events are stored locally and retried with exponential backoff
- Network interruptions are handled gracefully
- Event loss is minimized through persistent storage
- Automatic flushing on page unload

## Testing

To test the SDK under intermittent network conditions:

```javascript
// Simulate network failure
analytics.endpoint = 'https://nonexistent-endpoint.com';

// Track some events
analytics.trackPageView();
analytics.trackListingOpened('test_123');

// Restore endpoint
analytics.endpoint = '/v1/analytics/events';

// Events should be retried automatically
```

## Monitoring

Check the SDK status for debugging:

```javascript
console.log(analytics.getStatus());
// Output: { queueLength: 0, failedQueueLength: 0, isSending: false, sessionId: "...", userId: "..." }
```

## Troubleshooting

### Events not sending
- Check network connectivity
- Verify endpoint URL is correct
- Check browser console for errors

### High event loss
- Increase `maxRetries` configuration
- Check if localStorage is available
- Verify endpoint is accepting requests

### Performance issues
- Adjust `batchSize` and `flushInterval`
- Monitor queue lengths with `getStatus()`

## Version History

- **1.0.0**: Initial release with core event tracking and retry logic