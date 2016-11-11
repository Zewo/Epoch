Pod::Spec.new do |s|
  s.name         = "Reflection"
  s.version      = "0.14.2"
  s.summary      = "Advanced Swift Reflection"
  s.description  = <<-DESC
                    Reflection enables advanced runtime features like dynamic construction of types and manipulating instance properties.
                   DESC
  s.homepage     = "https://github.com/Zewo/Reflection"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Brad Hilton" => "brad@skyvive.com" }
  s.source       = { :git => "https://github.com/Zewo/Reflection.git", :tag => "0.14.2" }

  s.ios.deployment_target = "8.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.9"

  s.source_files  = "Sources", "Sources/**/*.{swift}"
  s.requires_arc = true
end
