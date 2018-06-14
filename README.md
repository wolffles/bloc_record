learning to make a ruby gem, also learning about ORMs.

At a minimum, a RubyGem needs a .gemspec file(typically `project_name.gemspec`) and one Ruby file (typically lib/project_name.rb)

A gemspec defines metadata about your RubyGem like its name, version and author.
  # A gemspec is called from a Ruby method — anything you can do in Ruby you can do in a gemspec.

We added a sqlite3 dependency using add_runtime_dependency. This instructs  bundle to install sqlite3-ruby, which provides a programmatic Ruby interface to SQLite. (It lets you write Ruby code instead of using the command line.)
