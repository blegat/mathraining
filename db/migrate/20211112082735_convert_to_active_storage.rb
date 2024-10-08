class ConvertToActiveStorage < ActiveRecord::Migration[5.2]
  require 'open-uri'

  def up
    # Following code is for postgres only
    get_blob_id = 'LASTVAL()'
    
    active_storage_blob_statement = ActiveRecord::Base.connection.raw_connection.prepare('active_storage_blob_statement', <<-SQL)
      INSERT INTO active_storage_blobs (
        key, filename, content_type, metadata, byte_size, checksum, created_at
      ) VALUES ($1, $2, $3, '{}', $4, $5, $6)
    SQL

    active_storage_attachment_statement = ActiveRecord::Base.connection.raw_connection.prepare('active_storage_attachment_statement', <<-SQL)
      INSERT INTO active_storage_attachments (
        name, record_type, record_id, blob_id, created_at
      ) VALUES ($1, $2, $3, #{get_blob_id}, $4)
    SQL

    Rails.application.eager_load!

    transaction do
      Myfile.find_each.each do |instance|
        if instance.send("file").path.blank?
          next
        end

        ActiveRecord::Base.connection.raw_connection.exec_prepared(
          'active_storage_blob_statement', [
            key(instance, "file"),
            instance.send("file_file_name"),
            instance.send("file_content_type"),
            instance.send("file_file_size"),
            checksum(instance.send("file")),
            instance.file_updated_at.iso8601
          ])

        ActiveRecord::Base.connection.raw_connection.exec_prepared(
          'active_storage_attachment_statement', [
            "file",
            Myfile.name,
            instance.id,
            instance.file_updated_at.iso8601,
          ])
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def key(instance, attachment)
    SecureRandom.uuid
    # Alternatively:
    # instance.send("#{attachment}_file_name")
  end

  def checksum(attachment)
    # local files stored on disk:
    url = attachment.path
    Digest::MD5.base64digest(File.read(url))
  end
end
