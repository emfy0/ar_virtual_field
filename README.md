# Active Record Virtual Field

Gem provides an easy mechanism to define virtual fields within an ActiveRecord model.
It allows defining attributes that are not directly stored in the database, but are instead computed or fetched using SQL queries.
Gem handles both the definition of these fields and the creation of scopes to query models with the virtual field included.

## Installation

Add gem to Gemfile:

```ruby
gem 'ar_virtual_field'
```

## Usage

### Defining a virtual field

To define a virtual field, use the virtual_field method in your model:

```ruby
virtual_field :virtual_attribute, 
  scope: -> { joins(:related_model).where(related_models: { some_column: value }) },
  select: -> { "SUM(related_models.some_value)" },
  get: -> { calculate_some_value },
  default: 0
```

Parameters:
  - `name`: The name of the virtual field.
  - `scope`: A lambda defining a scope that fetches the virtual field value (optional).
  - `select`: SQL selection logic (can be a string or arel node or a lambda returning a string or arel_node) to define how the field is computed.
  - `get`: A method to retrieve the value of the virtual field when the field isn't fetched via SQL.
  - `default`: A default value for the virtual field if the result is nil (optional).

Example:

```ruby
class User < ApplicationRecord
  virtual_field :total_orders,
    scope: -> { joins(:orders).group(:id) },
    select: -> { "COUNT(orders.id)" },
    get: -> { orders.count },
    default: 0

  virtual_field :fullname,
    select: -> { "name || surname" },
    get: -> { "#{name}#{surname}" }
end

users_with_orders = User.with_total_orders # queries database once

user = users_with_orders.first
user.total_orders # => value computed by database
user.fullname # => value computed by database
```

### Scopes and querying:

 - `with_#{name}`: Automatically generated scope to include the virtual field in queries. You can use this scope in your ActiveRecord queries like so:

```ruby
User.with_total_orders.where(ArVirtualField[:total_orders] => 5)
```

This will include the total_orders virtual field in the SQL query and allow filtering by it.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/emfy0/ar_virtual_field. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/emfy0/ar_virtual_field/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ArVirtualField project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/emfy0/ar_virtual_field/blob/main/CODE_OF_CONDUCT.md).
