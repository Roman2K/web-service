# WebService

REST client. Alternative to [`ActiveResource`](http://api.rubyonrails.org/classes/ActiveResource/Base.html).

## Installation

Since `WebService` depends on the gem `class-inheritable-attributes` which cannot be installed directly by RubyGems because the account name has to be prepended to the actual gem name, please refer to the corresponding README for how to install this dependency manually.

Then, install the `web-service` gem itself:

    $ gem install <gem> -s http://gems.github.com/

## Usage example

Let's say you have a Rails app exposing a RESTful API for articles and their comments:

    map.resources :articles, :has_many => :comments

When building the corresponding client for this API to consume these resources, the code could look like:

    require 'web_service'
    
    class BasicResource < WebService::Resource
      # Mandatory:
      self.site = WebService::Site.new("http://login:password@host:port")
      
      # Optional (and possibly in subclasses):
      self.site = WebService::Site.new("https://secure.site")
      self.credentials = ["login", "password"]
      self.element_name = "custom_element_name"
      self.singleton = true   # /foo instead of /foos/1
    end
    
    class Article < BasicResource
      has_many :comments
    end
    
    class Comment < BasicResource
      belongs_to :article
    end

### Attributes

    article = Article.new(:title => "First article")
    article.title    # => "First article"
    article.title?   # => true
    article.title = " "
    article.title?   # => false
    article.body     # raises NoMethodError
    article.body?    # raises NoMethodError

### CRUD

    article = Article.new(:title => "First article")
    begin
      article.save
      # => POST /articles
    rescue WebService::ResourceInvalid
      article.body = "Like the title says."
      article.save
      # => POST /articles
    end
    
    article.body += " Updated."
    article.save
    # => PUT /articles/1
    
    article.destroy
    # => DELETE /articles/1

### Fetching

    article.id            # => 1
    Article[1] == article # => true
    Article[99]           # => nil
    Article.find(99)      # raises WebService::ResourceNotFound
    
    Article.all           # => [Article[1], ..., Article[42]]
    Article.first         # => Article[1]
    Article.last          # => Article[42]
    
    comment = Comment.new(:article_id => 1)
    comment.article       # => Article[1]
    # => GET /articles/1
    comment.article       # => Article[1]
    # => (cache hit)

### Nested resources (associations)

Use `article.comments` like you would `Comment`, only scoped to `article`.

    article.comments.all
    # => GET /articles/1/comments

Associating a comment with a article:

    article.comments.create(:body => "First comment.")
    # => POST /articles/1/comments

The same in a more formal way:

    comment = Comment.new(:body => "First comment.")
    comment.article = article
    comment.article == article  # => true
    comment.article_id          # => 1
    comment.save

### Arbitrary actions

All of resource classes, resource instances and association collections respond to all four HTTP verbs (`GET`, `POST`, `PUT` and `DELETE`) to issue requests to arbitrary actions.

**Note:** these methods do not return resource instances, but rather plain unserialized objects, as returned by the server:

    Article.delete(:unpopular)         # => [{'id' => 5, ...}, ...]
    # => DELETE /articles/unpopular

    Article.get(:popular, :page => 2)  # => [{'id' => 1, ...}, ...]
    # => GET /articles/popular?page=2
    
    article.put(:publish, :at => 1.hour.from_now)
    # => PUT /articles/1/publish {:at => 1.hour.from_now}
    
    article.comments.put(:spam, 5)
    # => PUT /articles/1/comments/5/spam
    
    article.comments.get("/spam")
    # => PUT /articles/1/comments/spam

## Formats

* Requests are sent **JSON**-encoded.
* Responses can be returned either **JSON**- or **XML**-encoded.

## Status

*   Fetched resources should be cached in memory, so that the following returns true:

        comments = article.comments
        comments.all.object_id == comments.all.object_id

*   There are **tests** left to be written. Run `rake coverage` to find out what still has to be tested. Note that for RCov to work with Ruby 1.8.7, you might need to install the latest `rcov` gem from [GitHub](http://github.com/spicycode/rcov):

        gem install spicycode-rcov -s http://gems.github.com

