Pod::Spec.new do |s|
  s.name         = "AnalyticsKit"
  s.version      = "1.0.3"

  s.summary      = "Analytics framework for iOS"

  s.description  = <<-DESC
                      The goal of AnalyticsKit is to provide a consistent API for analytics regardless of which analytics provider you're using behind the scenes.

                      The benefit of using AnalyticsKit is that if you decide to start using a new analytics provider, or add an additional one, you need to write/change much less code!

                      AnalyticsKit works both in ARC based projects and non-ARC projects. 
                  DESC

  s.homepage     = "https://github.com/twobitlabs/AnalyticsKit"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.authors      = { "Two Bit Labs" => "", "Todd Huss" => "", "Susan Detwiler" => "", "Christopher Pickslay" => "", "Zac Shenker" => "", "Sinnerschrader Mobile" => "" }


  
  s.platform     = :ios
  s.source       = { :git => "https://github.com/twobitlabs/AnalyticsKit.git", :tag => s.version.to_s }

  s.subspec 'Core' do |core|
    core.source_files  = 'AnalyticsKit.{h,m}', 'AKEvent.{h,m}', 'AKDebugProvider.{h,m}', 'AKUnitTestProvider.{h,m}', 'Categories/NSNumber+Buckets.{h,m}'
  end
  
  s.subspec 'AdjustIO' do |a|
    a.source_files = 'Providers/AdjustIO/AKAdjustIOProvider.{h,m}'
    a.dependency 'AdjustIO', '2.1.0'
    a.dependency 'AnalyticsKit/Core'  
  end

  s.subspec 'Flurry' do |f|
    f.source_files = 'Providers/Flurry/AKFlurryProvider.{h,m}'
    f.dependency 'FlurrySDK'
    f.dependency 'AnalyticsKit/Core'
  end
  
  s.subspec 'GoogleAnalytics' do |ga|
    ga.source_files = 'Providers/Google Analytics/AKGoogleAnalyticsProvider.{h,m}'
    ga.dependency 'GoogleAnalytics-iOS-SDK', '~> 2.0beta4'
    ga.dependency 'AnalyticsKit/Core'
  end
  
  s.subspec 'Localytics' do |l|
    l.source_files = 'Providers/Localytics/AKLocalyticsProvider.{h,m}'
    l.dependency 'Localytics'
    l.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'Mixpanel' do |m|
    m.source_files = 'Providers/Mixpanel/AKMixpanelProvider.{h,m}'
    m.dependency 'Mixpanel'
    m.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'NewRelic' do |nr|
    nr.source_files = 'Providers/New Relic/AKNewRelicProvider.{h,m}'
    nr.dependency 'NewRelicAgent'
    nr.dependency 'AnalyticsKit/Core'
    nr.platform     = :ios, '5.0'
  end
  
  s.subspec 'Parse' do |p|
    p.source_files = 'Providers/Parse/AKParseProvider.{h,m}'
    p.dependency 'Parse-iOS-SDK'
    p.dependency 'AnalyticsKit/Core'
  end
  
  s.subspec 'TestFlight' do |tf|
    tf.source_files = 'Providers/TestFlight/AKTestFlightProvider.{h,m}'
    tf.dependency 'TestFlightSDK'
    tf.dependency 'AnalyticsKit/Core'
  end

end
