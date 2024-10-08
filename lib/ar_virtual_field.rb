# frozen_string_litera: true

require "active_record"

module ArVirtualField
  module HelperMethods
    def self.select_append(relation, *values)
      if relation.select_values.empty?
        values.unshift(relation.arel_table[Arel.star])
      end

      relation.select(*values)
    end

    def self.table_name(name)
      "#{name}_outer"
    end

    def self.table_with_column(name)
      "#{name}_outer.#{name}"
    end
  end

  class FieldsData < Hash
    def [](field)
      statement = super(field.to_sym)
      raise "Unknown virtual field `#{field}`" unless statement
      statement.()
    end
  end

  def virtual_fields
    @ar_virtual_fields || FieldsData.new
  end

  def virtual_field(name, scope: nil, select:, get:, default: nil)
    @ar_virtual_fields ||= FieldsData.new

    name = name.to_s
    current_class = self
    unwrap_arel_expression = -> (exp) { exp.is_a?(Arel::Nodes::NodeExpression) ? exp : Arel.sql(exp) }

    select_lambda =
      case select
      when Proc
        -> { unwrap_arel_expression.(select.()) }
      else
        arel = unwrap_arel_expression.(select)
        -> { arel }
      end

    if scope
      @ar_virtual_fields[name.to_sym] = -> { Arel.sql(HelperMethods.table_with_column(name)) }

      scope_name = :"_scope_#{name}"

      scope(scope_name, scope)

      scope(:"with_#{name}", -> do
        scope_query = current_class
          .send(scope_name)
          .select(select_lambda.().as(name), "#{table_name}.id")

        HelperMethods.select_append(joins(<<~SQL.squish), "#{HelperMethods.table_with_column(name)} AS #{name}")
          LEFT JOIN (#{scope_query.to_sql}) #{HelperMethods.table_name(name)}
            ON #{
              Array(primary_key).map do |pk|
                "#{HelperMethods.table_name(name)}.#{pk} = #{table_name}.#{pk}"
              end.join(' AND')
            }
        SQL
      end)
    else
      @ar_virtual_fields[name.to_sym] = -> { select_lambda.() }

      scope(:"with_#{name}", -> do
        HelperMethods.select_append(self, select_lambda.().as(name))
      end)
    end

    method_name = :"ar_virtual_field_#{name}"

    define_method(method_name, &get)
    define_method(name) do
      if ActiveRecord::Base.connection.query_cache_enabled
        attributes.key?(name) ? (self[name] || default) : send(method_name)
      else
        send(method_name)
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.extend(ArVirtualField)
end
