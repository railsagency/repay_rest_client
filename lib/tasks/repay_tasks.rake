# desc "Explaining what the task does"
# task :repay do
#   # Task goes here
# end
require 'rake/testtask'
task :default => [:test]
Rake::RepayTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/test_*"
  t.warning = false
end
