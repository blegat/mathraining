class RemoveLastBanDateFromUser < ActiveRecord::Migration[7.1]
  def change
    up_only do
      User.where.not(:last_ban_date => nil).each do |u|
        Sanction.create(:user_id => u.id, :sanction_type => :ban, :start_time => u.last_ban_date, :duration => 14, :reason => "Ce compte a été temporairement désactivé pour cause de plagiat. Il sera à nouveau accessible le [DATE]. L'équipe des correcteurs bénévoles de Mathraining vous invite à prendre de ce temps libre pour réfléchir à l'intérêt de leur faire corriger des solutions qui ne viennent pas de vous. Notez que la création d'un second compte est formellement interdite et résulterait en une sanction encore plus sévère que celle-ci.")
      end
    end
  
    remove_column :users, :last_ban_date, :datetime
  end
end
