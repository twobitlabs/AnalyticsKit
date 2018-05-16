#ifndef __mParticle__EventTypeName__
#define __mParticle__EventTypeName__

#include <string>
#include <vector>
#include <algorithm>

using namespace std;

namespace mParticle {
    enum EventType {
        /** Use for navigation related events */
        Navigation = 1,
        /** Use for location related events */
        Location = 2,
        /** Use for search related events */
        Search = 3,
        /** Use for transaction related events */
        Transaction = 4,
        /** Use for user content related events */
        Content = 5,
        /** Use for user preference related events */
        Preference = 6,
        /** Use for social related events */
        Social = 7,
        /** Use for other types of events not contained in this enum */
        Other = 8,
        /** 9 used to be Media. It has been discontinued */
        /** Internal. Used when a product is added to the cart */
        AddToCart = 10,
        /** Internal. Used when a product is removed from the cart */
        RemoveFromCart = 11,
        /** Internal. Used when the cart goes to checkout */
        Checkout = 12,
        /** Internal. Used when the cart goes to checkout with options */
        CheckoutOption = 13,
        /** Internal. Used when a product is clicked */
        Click = 14,
        /** Internal. Used when user views the details of a product */
        ViewDetail = 15,
        /** Internal. Used when a product is purchased */
        Purchase = 16,
        /** Internal. Used when a product refunded */
        Refund = 17,
        /** Internal. Used when a promotion is displayed */
        PromotionView = 18,
        /** Internal. Used when a promotion is clicked */
        PromotionClick = 19,
        /** Internal. Used when a product is added to the wishlist */
        AddToWishlist = 20,
        /** Internal. Used when a product is removed from the wishlist */
        RemoveFromWishlist = 21,
        /** Internal. Used when a product is displayed in a promotion */
        Impression = 22
    };
    
    class EventTypeName final {
        static const vector<string> names;
        static const vector<string> hashes;
        
    public:
        static const size_t count;
        static EventType eventTypeForHash(const string &hashString);
        static string hashForEventType(const EventType eventType);
        static string nameForEventType(const EventType eventType);
    };
}

#endif
