//
//  EventTypeName.h
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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
        Location,
        /** Use for search related events */
        Search,
        /** Use for transaction related events */
        Transaction,
        /** Use for user content related events */
        Content,
        /** Use for user preference related events */
        Preference,
        /** Use for social related events */
        Social,
        /** Use for other types of events not contained in this enum */
        Other,
        /** Use for media related events */
        Media,
        /** Internal. Used when a product is added to the cart */
        AddToCart,
        /** Internal. Used when a product is removed from the cart */
        RemoveFromCart,
        /** Internal. Used when the cart goes to checkout */
        Checkout,
        /** Internal. Used when the cart goes to checkout with options */
        CheckoutOption,
        /** Internal. Used when a product is clicked */
        Click,
        /** Internal. Used when user views the details of a product */
        ViewDetail,
        /** Internal. Used when a product is purchased */
        Purchase,
        /** Internal. Used when a product refunded */
        Refund,
        /** Internal. Used when a promotion is displayed */
        PromotionView,
        /** Internal. Used when a is clicked */
        PromotionClick,
        /** Internal. Used when a product is added to the wishlist */
        AddToWishlist,
        /** Internal. Used when a product is removed from the wishlist */
        RemoveFromWishlist,
        /** Internal. Used when a product is displayed in a promotion */
        Impression
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
