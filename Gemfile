# Automatically compute our required gems based on our Gemspec.  This code
# is based on http://gist.github.com/277349 .
gemspec_path = File.join(File.dirname(__FILE__), 'mongoid_attachment.gemspec')
gemspec = eval(File.read(gemspec_path))
gemspec.dependencies.each do |dep|
  if dep.name == 'mongoid'
    gem(dep.name, :git => 'git://github.com/durran/mongoid.git',
        :branch => 'legacy')
  else
    group = dep.type == :development ? :development : :default
    gem dep.name, dep.requirement, :group => group
  end
end
