---
layout: post
comments: true

title: "Rails 4 Custom Configurations"
date: 2015-04-02 22:08:00
tags: [Tips, Rails4, Ruby]
---

Was working on a Rails 4 side project when I realized that I should make a configuration file for a constant
that I wanted. I knew there was a way to do configuration in Rails, but wasn't sure what best practices were
so I looked it up. It turns out that as of Rails 4.2 there is now a configuration `x` namespace for you to
provide your own custom configurations!

<!--more-->

If you are developing in Rails 4.2+ then you have access to the `x` configuration namespace! Rails offers
four standard places to put initialization code:

* In the `config/application.rb` file: This is for configurations you need to run before Rails itself is
even loaded. This does not seem to be the recommended way as in the file it states: "Application configuration
should go into files in `config/initializers` all `.rb` files in that directory are automatically loaded."
* Environment-specific configuration files: These are under `config/environments/` folder such as
`config/environments/production.rb` and should be used for environment-specific configurations.
* Initializers files which are under `config/initializers`: This seems to be the suggested method mentioned
earlier and is the way I will implement it.
* After-initializers which seem to be utilized with `config.after_initialize` method in an initializer: This
would be for any configurations that need to be done after Rails has finished initializing and all other
initializers under `config/initializers` are completed.

## Initializers

You can add your own initializer under `config/initializers` as a `file_name.rb` and it will be loaded
automagically with all the other initializers in alphabetical order. I added a `my_app.rb` file to the
folder and put the following:

```ruby
# My application specific configurations
MyApp::Application.config.x.retries = 3
MyApp::Application.config.x.log_level = :debug
```

That's it! Simple, realize that this is specifically the `x` namespace and you cannot rename it! I originally
got tripped up by it because I thought you could use whatever you want as per [the documentation][rdoc] was
not super specific on the `x` portion. But as per the [4.2 release notes][release] it clearly states that
they "Introduced the `x` namespace for defining custom configuration options".

### Using Custom Configurations

Finally, to use your custom configurations anywhere, you can actually now do the following anywhere in your
application to use:

```ruby
Rails.configuration.x.retries    # => 3
Rails.configuration.x.log_level  # => :debug
```

That is all folks! Hope you learned a bit from the tip, and realize, sometimes they hide things in the
release notes that are helpful!

[rdoc]: http://guides.rubyonrails.org/v4.2.0/configuring.html#custom-configuration
[release]: http://guides.rubyonrails.org/4_2_release_notes.html#railties-notable-changes
