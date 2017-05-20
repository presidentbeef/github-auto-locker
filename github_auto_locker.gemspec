Gem::Specification.new do |s|
  s.name = %q{github-auto-locker}
  s.version = "1.1.0"
  s.authors = ["Justin Collins"]
  s.summary = "Simple script to lock closed GitHub issues over a certain age."
  s.description = <<DESC
Automatically locks GitHub issues older than a specified number of days.
This forces people to open new issues instead of attaching themselves to old (typically unrelated) issues. 
DESC
  s.homepage = "https://github.com/presidentbeef/github-auto-locker"
  s.files = ["bin/github-auto-locker", "README.md"] + Dir["lib/**/*"]
  s.executables = ["github-auto-locker"]
end
