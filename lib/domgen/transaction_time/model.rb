#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Transaction time facet
module Domgen
  FacetManager.facet(:transaction_time) do |facet|
    facet.enhance(Entity) do
      def pre_pre_complete
        attribute =
          self.entity.attribute_by_name?(:CreatedAt) ?
            self.entity.attribute_by_name(:CreatedAt) :
            self.entity.datetime(:CreatedAt, :immutable => true)

        if attribute.sync?
          puts "Should disable #{attribute.qualified_name}"
        end

        attribute.disable_facet(:sync) if attribute.sync?

        attribute =
          self.entity.attribute_by_name?(:DeletedAt) ?
            self.entity.attribute_by_name(:DeletedAt):
            self.entity.datetime(:DeletedAt, :set_once => true, :nullable => true)
        attribute.disable_facet(:sync) if attribute.sync?

        self.entity.unique_constraints.each do |constraint|
          # Force the creation of the index with filter specified. Parallels behaviours in sql facet.
          index = self.entity.sql.index(constraint.attribute_names, :unique => true)
          index.filter = "#{self.entity.sql.dialect.quote(:DeletedAt)} IS NULL"
        end if self.entity.sql?
        if self.entity.jpa?
          self.entity.jpa.default_jpql_criterion = 'O.deletedAt IS NULL'
          self.entity.jpa.create_default(:CreatedAt => 'now()', :DeletedAt => 'null')
          self.entity.jpa.update_default(:DeletedAt => nil)
          self.entity.jpa.update_defaults.each do |defaults|
            self.entity.jpa.update_default(defaults.values.merge(:DeletedAt => nil)) do |new_default|
              new_default.factory_method_name = defaults.factory_method_name
            end
            self.entity.jpa.remove_update_default(defaults)
          end
        end
        if self.entity.graphql? && self.entity.dao.graphql?
          self.entity.attribute_by_name(:CreatedAt).graphql.initial_value = 'new java.util.Date()'
          self.entity.attribute_by_name(:DeletedAt).graphql.initial_value = 'null'
          self.entity.attribute_by_name(:CreatedAt).graphql.updateable = false
          self.entity.attribute_by_name(:DeletedAt).graphql.updateable = false
        end
        if self.entity.imit?
          attributes = self.entity.attributes.select {|a| %w(CreatedAt DeletedAt).include?(a.name.to_s) && a.imit?}.collect {|a| a.name.to_s}
          if attributes.size > 0
            defaults = {}
            defaults[:CreatedAt] = 'org.realityforge.guiceyloops.shared.ValueUtil.now()' if attributes.include?('CreatedAt')
            defaults[:DeletedAt] = 'null' if attributes.include?('DeletedAt')
            self.entity.imit.test_create_default(defaults)
          end
        end
      end
    end
  end
end
