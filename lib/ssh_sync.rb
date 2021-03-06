# frozen_string_literal: true

require 'net/ssh'
require 'net/sftp'
require 'dotenv/load'

Dotenv.load

Net::SSH.start(
  ENV.fetch('HOST'),
  ENV.fetch('USER'),
  password: ENV.fetch('PASSWORD')
) do |ssh|
  ssh.sftp.connect do |sftp|
    Dir.foreach('.') do |file|
      puts file
    end
  end
end
