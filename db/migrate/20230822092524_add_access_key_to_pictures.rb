class AddAccessKeyToPictures < ActiveRecord::Migration[5.2]
  def change
    add_column :pictures, :access_key, :string
    up_only do
      Picture.all.each do |p|
        p.create_access_key
        p.save
      end
    end
  end
end
