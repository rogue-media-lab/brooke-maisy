# frozen_string_literal: true

# Cloudflare R2 rejects multiple checksums in a single S3 request.
# Rails 8.1 sends both CRC32C and MD5 by default, which R2 interprets
# as "multiple non-default checksums." This initializer forces CRC32C
# only, allowing uploads to Cloudflare R2 to succeed.

# See: https://github.com/rails/rails/issues/54028
# And: https://developers.cloudflare.com/r2/api/s3/api/

if defined?(ActiveStorage::Service::S3Service)
  require "active_storage/service/s3_service"

  ActiveStorage::Service::S3Service.prepend(Module.new do
    def upload(key, io, checksum: nil, **options)
      # Strip :md5 and :sha256 from options to prevent multiple checksums
      options.delete(:md5)
      options.delete(:sha256)
      super
    end
  end)
end
