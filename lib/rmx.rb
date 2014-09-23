require "rmx/version"

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

Motion::Project::App.setup do |app|
  app.vendor_project(File.expand_path('../../ext', __FILE__), :static, :cflags => "-fobjc-arc -ObjC -I#{File.join(Dir.pwd, "vendor/Pods/ReactiveCocoa/ReactiveCocoaFramework/ReactiveCocoa")}")
  %w(
    RMXObjectExtensions
    base
    env
    layout
    util
    accessors
    rac_app_signals
    events
    ui
    RACSignal+RMX
    RMXCommonMethods
    RMXLongTask
    RMXWeakHolder
    RMXUnsafeUnretainedHolder
    RMXWeakToStrongHash
    RMXStrongToWeakHash
    RMXSynchronizedStrongToWeakHash
    RMXSetAttributes
    RMXConcurrentOperation
    RMXEventManager
    RMXViewControllerPresentation
    RMXKeyboardHelpers
    RMXHideTableViewHeader
    RMXNavigationController
    RMXTableViewController
    RMXViewController
    RMXSegmentedController
    RMXInputAccessoryViewResponder
    RMXView
    RMXActionSheet
    RMXAutoLayoutLabel
    RMXAutoLayoutScrollView
    RMXTableViewCell
    RMXTableViewHeaderFooterView
    RMXTableHandler
    RMXTableHandlerViewCell
    RMXTableHandlerViewHeaderFooterView
  ).reverse.each do |x|
    app.files.unshift(File.join(File.dirname(__FILE__), "motion/#{x}.rb"))
  end
  FileUtils.mkdir_p(File.expand_path("../build", File.dirname(__FILE__)))
  env_filename = File.expand_path("../build/env.rb", File.dirname(__FILE__))
  rmx_env = ENV['rmx_env'] == '1' ? ENV.to_hash : {}
  File.open(env_filename, "w") do |f|
    f.puts %Q{class RMX\n  Env = #{rmx_env.inspect}\nend\n}
  end
  App.log "RMX::Env", rmx_env.inspect
  app.files.unshift(env_filename)
end
