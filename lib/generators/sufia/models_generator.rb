class Sufia::ModelsGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :model_name, type: :string, default: 'user'
  desc '
This generator makes the following changes to your application:
 1. Creates the curation_concerns.rb configuration file and several others
 2. Creates the file_set.rb and collection.rb models
       '
  def banner
    say_status('warning', 'GENERATING SUFIA MODELS', :yellow)
  end

  # Setup the database migrations
  def copy_migrations
    rake 'curation_concerns:install:migrations'
    rake 'sufia:install:migrations'
  end

  # Add behaviors to the user model
  def inject_curation_concerns_user_behavior
    file_path = "app/models/#{model_name.underscore}.rb"
    if File.exist?(file_path)
      inject_into_file file_path, after: /include Hydra\:\:User.*$/ do
        "\n  # Connects this user object to Curation Concerns behaviors." \
        "\n  include CurationConcerns::User\n" \
        "\n  # Connects this user object to Sufia behaviors." \
        "\n  include Sufia::User" \
        "\n  include Sufia::UserUsageStats\n"
      end
    else
      puts "     \e[31mFailure\e[0m  Sufia requires a user object. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g curation_concerns client"
    end
  end

  def create_collection
    copy_file 'app/models/collection.rb', 'app/models/collection.rb'
    copy_file 'spec/models/collection_spec.rb', 'spec/models/collection_spec.rb' if rspec_installed?
  end

  def create_file_set
    copy_file 'app/models/file_set.rb', 'app/models/file_set.rb'
    copy_file 'spec/models/file_set_spec.rb', 'spec/models/file_set_spec.rb' if rspec_installed?
  end

  # Adds clamav initializtion
  def clamav
    generate 'sufia:clamav'
  end

  private

    def rspec_installed?
      defined?(RSpec) && defined?(RSpec::Rails)
    end
end