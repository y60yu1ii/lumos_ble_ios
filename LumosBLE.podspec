Pod::Spec.new do |s|
          #1.
          s.name            = "LumosBLE"
          #2.
          s.version         = "0.0.3"
          #3.  
          s.summary         = "Simplest ble module"
          #4.
          s.homepage        = "https://github.com/y60yu1ii/lumos_ble_ios"
          #5.
          s.license         = "MIT"
          #6
          s.author          = "yaoyu"
          #7.
          s.platform        = :ios, "8.0"
          #8
          s.source          = { :git => "URL", :tag => "0.0.3" }
          #9.
          s.source_files    = "LumosBLE", "LumosBLE/**/*.{h,m,swift}"
          #10.
          s.swift_version   = '4.2'
    end
