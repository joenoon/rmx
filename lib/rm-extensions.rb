require "rm-extensions/version"

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

Motion::Project::App.setup do |app|
  %w(
    util
    retention
    accessors
    deallocation
    context
    observation
    queues
  ).reverse.each do |x|
    app.files.unshift(File.join(File.dirname(__FILE__), "motion/#{x}.rb"))
  end
  app.vendor_project(File.join(File.dirname(__FILE__), '../ext'), :static)
end
