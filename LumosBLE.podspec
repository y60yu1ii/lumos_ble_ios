Pod::Spec.new do |s|
          #1.
          s.name               = "LumosBLE"
          #2.
          s.version            = "0.0.1"
          #3.  
          s.summary         = "Simplest ble module"
          #4.
          s.homepage        = "http://lumosble.fishare.de"
          #5.
          s.license              = "MIT"
          #6.
          s.author               = "yaoyu"
          #7.
          s.platform            = :ios, "10.0"
          #8.
          s.source              = { :git => "URL", :tag => "0.0.1" }
          #9.
          s.source_files     = "LumosBLE", "LumosBLE/**/*.{h,m,swift}"
    end