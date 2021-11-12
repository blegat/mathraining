#!bin/rails runner

def move_to_storage(start_id, end_id)
  ActiveStorage::Attachment.where("id >= ? AND id <= ?", start_id, end_id).each do |attachment|
    name = attachment.name

    source = attachment.record.send(name).path
    dest_dir = File.join(
      "../storage",
      attachment.blob.key.first(2),
      attachment.blob.key.first(4).last(2))
    dest = File.join(dest_dir, attachment.blob.key)

    FileUtils.mkdir_p(dest_dir)
    puts "#{attachment.id} - Moving #{source} to #{dest}"
    FileUtils.cp(source, dest)
  end
end
