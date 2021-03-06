module Hyrax
  module Collections
    class PermissionsCreateService
      # @api public
      #
      # Set the default permissions for a (newly created) collection
      #
      # @param collection [Collection] the collection the new permissions will act on
      # @param creating_user [User] the user that created the collection
      # @param grants [Array<Hash>] additional grants to apply to the new collection
      # @return [Hyrax::PermissionTemplate]
      def self.create_default(collection:, creating_user:, grants: [])
        collection_type = Hyrax::CollectionType.find_by_gid!(collection.collection_type_gid)
        access_grants = access_grants_attributes(collection_type: collection_type, creating_user: creating_user, grants: grants)
        PermissionTemplate.create!(source_id: collection.id,
                                   access_grants_attributes: access_grants.uniq)
        collection.reset_access_controls!
      end

      # @api private
      #
      # Gather the default permissions needed for a new collection
      #
      # @param collection_type [CollectionType] the collection type of the new collection
      # @param creating_user [User] the user that created the collection
      # @param grants [Array<Hash>] additional grants to apply to the new collection
      # @return [Hash] a hash containing permission attributes
      def self.access_grants_attributes(collection_type:, creating_user:, grants:)
        [
          { agent_type: 'group', agent_id: admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE }
        ].tap do |attribute_list|
          # Grant manage access to the creating_user if it exists
          if creating_user
            attribute_list << { agent_type: 'user', agent_id: creating_user.user_key, access: Hyrax::PermissionTemplateAccess::MANAGE }
          end
        end + managers_of_collection_type(collection_type: collection_type) + grants
      end
      private_class_method :access_grants_attributes

      # @api private
      #
      # Retrieve the users or groups with manage permissions for a collection type
      #
      # @param collection_type [CollectionType] the collection type of the new collection
      # @return [Hash] a hash containing permission attributes
      def self.managers_of_collection_type(collection_type:)
        attribute_list = []
        user_managers = Hyrax::CollectionTypes::PermissionsService.user_edit_grants_for_collection_of_type(collection_type: collection_type)
        user_managers.each do |user|
          attribute_list << { agent_type: 'user', agent_id: user, access: Hyrax::PermissionTemplateAccess::MANAGE }
        end
        group_managers = Hyrax::CollectionTypes::PermissionsService.group_edit_grants_for_collection_of_type(collection_type: collection_type)
        group_managers.each do |group|
          attribute_list << { agent_type: 'group', agent_id: group, access: Hyrax::PermissionTemplateAccess::MANAGE }
        end
        attribute_list
      end
      private_class_method :managers_of_collection_type

      # @api private
      #
      # The value of the admin group name
      #
      # @return [String] a string representation of the admin group name
      def self.admin_group_name
        ::Ability.admin_group_name
      end
      private_class_method :admin_group_name
    end
  end
end
