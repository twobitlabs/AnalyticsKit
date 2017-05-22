Pod::Spec.new do |s|
  s.name         = "AnalyticsKit"
  s.version      = "2.1.0"

  s.summary      = "Analytics framework for iOS"

  s.description  = <<-DESC
                      The goal of AnalyticsKit is to provide a consistent API for analytics regardless of which analytics provider you're using behind the scenes.

                      The benefit of using AnalyticsKit is that if you decide to start using a new analytics provider, or add an additional one, you need to write/change much less code!

                      AnalyticsKit works both in ARC based projects and non-ARC projects.
                  DESC

  s.homepage     = "https://github.com/twobitlabs/AnalyticsKit"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.authors      = { "Two Bit Labs" => "", "Todd Huss" => "", "Susan Detwiler" => "", "Christopher Pickslay" => "", "Zac Shenker" => "", "Sinnerschrader Mobile" => "" }



  s.platform     = :ios, '8.4'
  s.source       = { :git => "https://github.com/twobitlabs/AnalyticsKit.git", :tag => s.version.to_s }
  s.requires_arc = false

  s.subspec 'Core' do |core|
    core.source_files  = 'AnalyticsKit.swift', 'AnalyticsKitEvent.swift', 'AnalyticsKitDebugProvider.swift', 'AnalyticsKitUnitTestProvider.swift', 'AnalyticsKit/AnalyticsKit/AnalyticsKitTimedEventHelper.swift'
  end

  s.subspec 'Intercom' do |i|
    i.source_files = 'Providers/Intercom/AnalyticsKitIntercomProvider.swift'
    i.frameworks = 'Intercom'
    i.dependency 'Intercom'
    i.dependency 'AnalyticsKit/Core'
    i.pod_target_xcconfig = {
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/Intercom/Intercom'
      # 'OTHER_LDFLAGS'          => '$(inherited) -undefined dynamic_lookup'
    }
  end

  s.subspec 'Crashlytics' do |c|
    c.source_files = 'Providers/Crashlytics/AnalyticsKitCrashlyticsProvider.swift'
    c.frameworks = 'Crashlytics', 'Security', 'SystemConfiguration'
    c.libraries = 'c++', 'z'
    c.dependency 'Crashlytics'
    c.dependency 'AnalyticsKit/Core'
    c.pod_target_xcconfig = {
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/Crashlytics/iOS'
      # 'OTHER_LDFLAGS'          => '$(inherited) -undefined dynamic_lookup'
    }
  end

  s.subspec 'Firebase' do |f|
    f.source_files = 'Providers/Firebase/AnalyticsKitFirebaseProvider.swift'
    f.dependency 'Firebase'
    f.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'Apsalar' do |a|
    a.source_files = 'Providers/Apsalar/AnalyticsKitApsalarProvider.swift'
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
    l.source_files = 'Providers/Localytics/AnalyticsKitLocalyticsProvider.swift'
    l.dependency 'Localytics'
    l.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'GoogleAnalytics' do |g|
    g.source_files = 'Providers/Google Analytics/AnalyticsKitGoogleAnalyticsProvider.swift'
    g.dependency 'GoogleAnalytics'
    g.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'Mixpanel' do |m|
    m.source_files = 'Providers/Mixpanel/AnalyticsKitMixpanelProvider.swift'
    m.dependency 'Mixpanel', '~> 3.1.4'
    m.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'NewRelic' do |n|
    n.source_files = 'Providers/New Relic/AnalyticsKitNewRelicProvider.swift'
    n.dependency 'NewRelicAgent'
    n.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'mParticle' do |n|
    n.source_files = 'Providers/mParticle/AnalyticsKitMParticleProvider.swift'
    n.dependency 'mParticle'
    n.dependency 'AnalyticsKit/Core'
  end

  s.subspec 'Parse' do |p|
    p.source_files = 'Providers/Parse/AnalyticsKitParseProvider.swift'
    p.dependency 'Parse'
    p.dependency 'AnalyticsKit/Core'
  end

end
