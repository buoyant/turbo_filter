# TurboFilter

Filters your ActiveRecord table records.

## Installation

Add this line to your application's Gemfile:

    gem 'turbo_filter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install turbo_filter

## Usage

  Add turbo_filter to application.js

    //= require turbo_filter

  In Controller:

    class ArticlesController < ApplicationController
    ...
      def index
        retrieve_turbo_filter_query(Article)
        @articles = Article.where(@turbo_filter_query.statement).paginate(page: params[:page], per_page: 100)
      end
    ...
    end

  In Models: Add `to_s` method like below to `Article -> belongs_to` assocation classes.

    class User < ActiveRecord::Base
    ...
      def to_s
        name
      end
    ...
    end

  In Views: Add `turbo_filters` helper method to `app/views/articles/index.html.erb` view filters.

    <%= turbo_filters %>

  UI Compatibility: boostrap compatible.
  Requires jQueryDatePicker, Turbo links enabled.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
