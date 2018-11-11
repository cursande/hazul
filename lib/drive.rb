# frozen_string_literal: true
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

class DriveClient
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Hazul'
  CREDENTIALS_PATH = './credentials/credentials.json'
  TOKEN_PATH = './credentials/token.yaml'

  # Initialize the API
  def initialize
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
  end

  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    user_id = 'default'
    credentials = user_authorizer.get_credentials(user_id)
    if credentials.nil?
      url = user_authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = user_authorizer.get_and_store_credentials_from_code(
        user_id: user_id,
        code: code,
        base_url: OOB_URI
      )
    end
    credentials
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
      Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY,
      Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    )
  end
end

client = DriveClient.new

client.display_files(5)
