Pod::Spec.new do |s|
  s.name         = "AnalyticsKit"
  s.version      = "2.0.0"

  s.summary      = "Analytics framework for iOS"

  s.description  = <<-DESC
                      The goal of AnalyticsKit is to provide a consistent API for analytics regardless of which analytics provider you're using behind the scenes.

                      The benefit of using AnalyticsKit is that if you decide to start using a new analytics provider, or add an additional one, you need to write/change much less code!

                      AnalyticsKit works both in ARC based projects and non-ARC projects.
                  DESC

  s.homepage     = "https://github.com/twobitlabs/AnalyticsKit"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.authors      = { "Two Bit Labs" => "", "Todd Huss" => "", "Susan Detwiler" => "", "Christopher Pickslay" => "", "Zac Shenker" => "", "Sinnerschrader Mobile" => "" }



  s.platform     = :ios, '8.0'
  s.source       = { :git => "https://github.com/twobitlabs/AnalyticsKit.git", :tag => s.version.to_s }
  s.requires_arc = false

  s.subspec 'Core' do |core|
    core.source_files  = 'AnalyticsKit.swift', 'AnalyticsKitEvent.{h,m}', 'AnalyticsKitDebugProvider.swift', 'AnalyticsKitUnitTestProvider.{h,m}', 'Categories/NSNumber+Buckets.{h,m}', 'AnalyticsKit/AnalyticsKit/AnalyticsKitTimedEventHelper.{h,m}'
  end

  s.subspec 'Crashlytics' do |a|
    a.source_files = 'Providers/Crashlytics/AnalyticsKitCrashlyticsProvider.swift'
    a.dependency 'Crashlytics'
    a.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'AdjustIO' do |a|
    a.source_files = 'Providers/AdjustIO/AnalyticsKitAdjustIOProvider.swift'
    a.dependency 'Adjust', '~> 4.5'
    a.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'Flurry' do |f|
    f.source_files = 'Providers/Flurry/AnalyticsKitFlurryProvider.swift'
    f.dependency 'Flurry-iOS-SDK/FlurrySDK'
    f.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'Localytics' do |l|
    l.source_files = 'Providers/Localytics/AnalyticsKitLocalyticsProvider.{h,m}'
    l.dependency 'Localytics-iOS-Client'
    l.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'Mixpanel' do |m|
    m.source_files = 'Providers/Mixpanel/AnalyticsKitMixpanelProvider.{h,m}'
    m.dependency 'Mixpanel', '~> 2.5.3'
    m.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'Parse' do |p|
    p.source_files = 'Providers/Parse/AnalyticsKitParseProvider.{h,m}'
    p.dependency 'Parse'
    p.dependency 'AnalyticsKit/Core'
  end

end
