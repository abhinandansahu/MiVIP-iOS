Pod::Spec.new do |s|
  s.name         = "react-native-mivip"
  s.version      = "1.0.0"
  s.summary      = "MiVIP React Native Bridge"
  s.homepage     = "https://github.com/Mitek-Systems/MiVIP-iOS"
  s.license      = "MIT"
  s.authors      = { "Mitek" => "support@miteksystems.com" }
  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/Mitek-Systems/MiVIP-iOS.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  
  s.dependency "React-Core"
  s.dependency "MiVIP", "3.6.15"
end
