#include "EventTypeName.h"
#include "MPHasher.h"

namespace mParticle {
    const vector<string> EventTypeName::names = {"Unknown", "Navigation", "Location", "Search", "Transaction", "UserContent", "UserPreference", "Social", "Other", "Media(discontinued)", // 0-9
                                                 "ProductAddToCart", "ProductRemoveFromCart", "ProductCheckout", "ProductCheckoutOption", "ProductClick", "ProductViewDetail", "ProductPurchase", "ProductRefund", // 10-17
                                                 "PromotionView", "PromotionClick", "ProductAddToWishlist", "ProductRemoveFromWishlist", "ProductImpression"}; // 18-22
    
    const size_t EventTypeName::count = EventTypeName::names.size();
    
    const vector<string> EventTypeName::hashes = []{
        vector<int> eventTypes(EventTypeName::count);
        int i = 0;
        for_each(eventTypes.begin(), eventTypes.end(), [&i](int &eventType) {eventType = i++;});
        vector<string> hashes = Hasher::hashedEventTypes(eventTypes);
        return hashes;
    }();
    
    EventType EventTypeName::eventTypeForHash(const string &hashString) {
        EventType eventType = Other;

        const auto firstEventHash = hashes.begin();
        const auto lastEventHash = hashes.end();
        const auto iterator = find(firstEventHash, lastEventHash, hashString);

        if (iterator != lastEventHash) {
            eventType = static_cast<EventType>(distance(firstEventHash, iterator));
        }

        return eventType;
    }

    string EventTypeName::hashForEventType(const EventType eventType) {
        auto hash = EventTypeName::hashes[eventType];
        return hash;
    }
    
    string EventTypeName::nameForEventType(const EventType eventType) {
        auto eventName = EventTypeName::names[eventType];
        return eventName;
    }
}
