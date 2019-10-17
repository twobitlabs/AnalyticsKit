#include "EventTypeName.h"
#include "MPHasher.h"
#import "MPIConstants.h"

namespace mParticle {
    const vector<string> EventTypeName::names = {
        string(kMPEventTypeStringUnknown.UTF8String),
        string(kMPEventTypeStringNavigation.UTF8String),
        string(kMPEventTypeStringLocation.UTF8String),
        string(kMPEventTypeStringSearch.UTF8String),
        string(kMPEventTypeStringTransaction.UTF8String),
        string(kMPEventTypeStringUserContent.UTF8String),
        string(kMPEventTypeStringUserPreference.UTF8String),
        string(kMPEventTypeStringSocial.UTF8String),
        string(kMPEventTypeStringOther.UTF8String),
        string(kMPEventTypeStringMediaDiscontinued.UTF8String),
        string(kMPEventTypeStringProductAddToCart.UTF8String),
        string(kMPEventTypeStringProductRemoveFromCart.UTF8String),
        string(kMPEventTypeStringProductCheckout.UTF8String),
        string(kMPEventTypeStringProductCheckoutOption.UTF8String),
        string(kMPEventTypeStringProductClick.UTF8String),
        string(kMPEventTypeStringProductViewDetail.UTF8String),
        string(kMPEventTypeStringProductPurchase.UTF8String),
        string(kMPEventTypeStringProductRefund.UTF8String),
        string(kMPEventTypeStringPromotionView.UTF8String),
        string(kMPEventTypeStringPromotionClick.UTF8String),
        string(kMPEventTypeStringProductAddToWishlist.UTF8String),
        string(kMPEventTypeStringProductRemoveFromWishlist.UTF8String),
        string(kMPEventTypeStringProductImpression.UTF8String),
        string(kMPEventTypeStringMedia.UTF8String)
    };
    
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
