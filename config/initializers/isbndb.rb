require 'isbndb'

ISBNdb::ApiClient.base_uri 'https://api.premium.isbndb.com/'
ISBNDB_CLIENT = ISBNdb::ApiClient.new(api_key: Rails.application.credentials.dig(:isbndb, :key))
