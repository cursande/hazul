# frozen_string_literal: true
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'launchy'

class DriveClient
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Hazul'
  CREDENTIALS_PATH = __dir__ + '/../credentials/credentials.json'
  TOKEN_PATH = __dir__ + '/../credentials/token.yaml'

  # Initialize the API
  def initialize
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
  end

  def authorize
    user_id = 'default'
    credentials = user_authorizer.get_credentials(user_id)
    credentials || fetch_and_store_credentials(user_id)
  end

  def fetch_and_store_credentials(user_id)
    Launchy.open(user_authorizer.get_authorization_url(base_url: OOB_URI))

    puts 'Paste code here:'

    code = gets
    credentials = user_authorizer.get_and_store_credentials_from_code(
      user_id: user_id,
      code: code,
      base_url: OOB_URI
    )
  end

  # Lists n most recently modified files
  def display_files(n)
    response = service.list_files(
      page_size: n,
      fields: 'nextPageToken, files(id, name)'
    )

    puts 'Files:'
    puts 'No files found' if response.files.empty?
    response.files.each do |file|
      puts "#{file.name} (#{file.id})"
    end
  end

  private

  def service
    @service ||= Google::Apis::DriveV3::DriveService.new
  end

  def user_authorizer
    @user_authorizer ||= Google::Auth::UserAuthorizer.new(
      Google::Auth::ClientId.from_file(CREDENTIALS_PATH),
      Google::Apis::DriveV3::AUTH_DRIVE_FILE,
      Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    )
  end
end
