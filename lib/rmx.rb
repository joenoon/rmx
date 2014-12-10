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
    util
    layout
    accessors
    instance_variables
    dealloc_logging
    rac_app_signals
    rac_macros
    ui
    rmx_shortcut
    RACStream+RMX
    UIView+RMX
    RMXCommonMethods
    RMXLongTask
    RMXWeakHolder
    RMXUnsafeUnretainedHolder
    RMXSetAttributes
    RMXEventManager
    RMXViewControllerPresentation
    RMXKeyboardHelpers
    UIResponder+RMX
    RMXNavigationController
    RMXTableViewController
    RMXViewController
    RMXSegmentedController
    RMXInputAccessoryViewResponder
    RMXView
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
  rmx_env_string_parts = []
  rmx_env_string_parts << "class RMX"
  rmx_env_string_parts << "  start_time = Time.now"
  rmx_env_string_parts << "  rmx_env = {}"
  # each env var is put into a hash with key and value obfuscated.
  # a comment is prepended for the developer with the unobfuscated value, but does not make it into the binary.
  # thanks to @lrz for the ord/chr idea.
  rmx_env.each_pair do |k, v|
    k_ords = k.to_s.scan(/./).map { |x| x.ord }
    v_ords = v.to_s.scan(/./).map { |x| x.ord }
    rmx_env_string_parts << "  # rmx_env[#{k.inspect}] = #{v.inspect}"
    rmx_env_string_parts << "  rmx_env[#{k_ords.inspect}.map { |x| x.chr }.join] = #{v_ords.inspect}.map { |x| x.chr }.join"
  end
  rmx_env_string_parts << "  Env = rmx_env.freeze"
  rmx_env_string_parts << "  TimeToParseEnv = (Time.now - start_time).freeze"
  rmx_env_string_parts << "end"
  File.open(env_filename, "w") do |f|
    f.puts rmx_env_string_parts.join("\n")
  end
  App.log "RMX::Env", rmx_env.inspect
  app.files.unshift(env_filename)
end
