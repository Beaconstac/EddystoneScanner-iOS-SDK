Pod::Spec.new do |s|
  s.name             = 'EddystoneScanner'
  s.version          = '1.2.15'
  s.swift_version    = '5.0'
  s.summary          = 'Eddystone scanner framework for iOS written in swift.'

  s.description      = <<-DESC
Framework to scan for eddystone compliant beacons build on Swift for iOS.
                       DESC

  s.homepage         = 'https://github.com/Beaconstac/EddystoneScanner-iOS-SDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'firecast' => 'amit.dp180@gmail.com' }
  s.source           = { :git => 'https://github.com/Beaconstac/EddystoneScanner-iOS-SDK.git', :tag => "v#{s.version}" }

  s.frameworks       = 'Foundation', 'CoreBluetooth'
  s.requires_arc     = true
  s.ios.deployment_target = '11.0'

  s.source_files = 'EddystoneScanner/*.swift', 'EddystoneScanner/**/*.swift'
end
