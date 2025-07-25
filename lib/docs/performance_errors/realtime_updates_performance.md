# Real-time Updates Performance Considerations (Pusher)

This document outlines performance considerations related to real-time data updates using Pusher. It examines interactions between the `PusherService` and various providers that consume Pusher events, such as `AdProvider`, `BlogProvider`, `GigProvider`, and `ProductProvider`.

## Potential Issues and Recommendations:

*   **Centralized vs. Decentralized Event Handling and Parsing:** Many providers subscribe to Pusher channels and bind to specific events. When a new event comes in the `PusherService` pushes this event to the specific provider. Providers then handle the event by parsing it. It's important that all providers use the same optimized method for parsing events.
    *   **Recommendation:** Centralize the event parsing data. For example, there should only be one method to read a BlogPost. With this each provider gets its data in an equal and performant manner. As is, some events can take longer if they are very nested and some might skip key steps if they aren't properly configured.

*   **JSON Parsing Overhead in Event Handlers:** The most significant performance concern with real-time updates is the overhead of parsing JSON data within the Pusher event handlers in various providers. Asynchronous parsing for JSON objects must be enforced within all Pusher events to avoid lockups.
    *   **Recommendation:** Enforce asynchronous event parsing. Review the following files: 
        *   `AdProvider`
        *   `BlogProvider`
        *   `GigProvider`
        *   `ProductProvider`
        Ensure all events are parsed asynchronously using `compute`.

*   **Sequential Subscription and Binding:** The most significant performance concern with Pusher revolves around subscribing and binding too many channels. The key concern is when the app hits its rate limit, which is 100 channels.
    *   **Recommendation:** Use dynamic subscriptions for each user and/or limit it to the business needs. Ensure that the subscriptions and bindings are as minimal as possible. Also ensure to unsubscribe from channels to prevent exessive usage.

*   **Over-reliance on `notifyListeners()`:** Ensure each provider does not call `notifyListeners` when it recieves a Pusher event. Some events might not need a refresh.
    *   **Recommendation:** Use a granular update mechanism. For example, each object that is being provided to a provider is broken up.

## Specific Code Locations to Review:

*   Examine all `_handle...Event` functions within all providers using Pusher, especially `AdProvider`, `BlogProvider`, `GigProvider`, and `ProductProvider`.
*   Review centralize the process of using Pusher and all the providers to ensure no double calls are being performed.

## Related Files:

*   `lib/services/pusher_service.dart`
*   `lib/providers/ad_provider.dart`
*   `lib/providers/blog_provider.dart`
*   `lib/providers/gig_provider.dart`
*   `lib/providers/product_provider.dart`
