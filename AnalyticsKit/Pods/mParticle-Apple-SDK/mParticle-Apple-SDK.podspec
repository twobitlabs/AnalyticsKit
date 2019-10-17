Pod::Spec.new do |s|
    s.name             = "mParticle-Apple-SDK"
    s.version          = "7.12.3"
    s.summary          = "mParticle Apple SDK."

    s.description      = <<-DESC
                         This is the mParticle Apple SDK for iOS and tvOS.
                         
                         At mParticle our mission is straightforward: make it really easy for apps and app services to connect and allow you to take ownership of your 1st party data.
                         Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing,
                         monetization, etc. However, embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs.

                         The mParticle platform addresses all these problems. We support an ever growing number of integrations with services and SDKs, including developer
                         tools, analytics, attribution, messaging, advertising, and more. mParticle has been designed to be the central hub connecting all these services –
                         read the [docs](https://docs.mparticle.com/developers/sdk/ios/) or contact us at <support@mparticle.com> to learn more.
                         DESC

    s.homepage          = "https://www.mparticle.com"
    s.license           = { :type => 'Apache 2.0', :file => 'LICENSE'}
    s.author            = { "mParticle" => "support@mparticle.com" }
    s.source            = { :git => "https://github.com/mParticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.documentation_url = "https://docs.mparticle.com/developers/sdk/ios/"
    s.social_media_url  = "https://twitter.com/mparticle"
    s.requires_arc      = true
    s.default_subspec   = 'mParticle'
    s.module_name       = "mParticle_Apple_SDK"

    pch_mParticle       = <<-EOS
                          #ifndef TARGET_OS_IOS
                              #define TARGET_OS_IOS TARGET_OS_IPHONE
                          #endif

                          #ifndef TARGET_OS_WATCH
                              #define TARGET_OS_WATCH 0
                          #endif

                          #ifndef TARGET_OS_TV
                              #define TARGET_OS_TV 0
                          #endif
                          EOS
    s.prefix_header_contents = pch_mParticle
    s.ios.deployment_target  = "8.0"
    s.tvos.deployment_target = "9.0"

    s.subspec 'mParticle' do |ss|
        ss.public_header_files = `./Scripts/find_headers.rb --public`.split("\n")

        ss.preserve_paths       = 'mParticle-Apple-SDK', 'mParticle-Apple-SDK/**', 'mParticle-Apple-SDK/**/*'
        ss.source_files         = 'mParticle-Apple-SDK/**/*'
        ss.libraries            = 'c++', 'sqlite3', 'z'

        ss.ios.frameworks       = 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
        ss.ios.weak_frameworks  = 'iAd', 'UserNotifications'

        ss.tvos.frameworks      = 'AdSupport', 'CoreGraphics', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
    end

    s.subspec 'AppExtension' do |ext|
        ext.public_header_files = `./Scripts/find_headers.rb --public`.split("\n")

        ext.preserve_paths       = 'mParticle-Apple-SDK', 'mParticle-Apple-SDK/**', 'mParticle-Apple-SDK/**/*'
        ext.source_files         = 'mParticle-Apple-SDK/**/*'
        ext.libraries            = 'c++', 'sqlite3', 'z'

        ext.ios.frameworks       = 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
        ext.ios.weak_frameworks  = 'iAd', 'UserNotifications'

        ext.tvos.frameworks      = 'AdSupport', 'CoreGraphics', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
    end
end

