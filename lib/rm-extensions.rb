require "rm-extensions/version"

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

Motion::Project::App.setup do |app|
  %w(
    env
    common_methods
    layout
    util
    accessors
    weak_holder
    weak_to_strong_hash
    strong_to_weak_hash
    events
    queues
    work_in_progress
  ).reverse.each do |x|
    app.files.unshift(File.join(File.dirname(__FILE__), "motion/#{x}.rb"))
  end
  FileUtils.mkdir_p(File.expand_path("../build", File.dirname(__FILE__)))
  env_filename = File.expand_path("../build/env.rb", File.dirname(__FILE__))
  rmext_env = ENV['rmext_env'] == '1' ? ENV.to_hash : {}
  File.open(env_filename, "w") do |f|
    f.puts %Q{module RMExtensions\n  Env = #{rmext_env.inspect}\nend\n}
  end
  App.log "RMExtensions::Env", rmext_env.inspect
  app.files.unshift(env_filename)
end
