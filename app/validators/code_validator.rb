class CodeValidator < ActiveModel::Validator
  def validate(record)
    code = record.code
    if code.nil? || code.length != 5
      record.errors.add(:base, "Le code doit contenir exactement 5 caractères.")
      return;
    end
    
    (0..4).each do |i|
      unless (code[i].ord >= 'A'.ord && code[i].ord <= 'Z'.ord) || (code[i].ord >= '0'.ord && code[i].ord <= '9'.ord)
        record.errors.add(:base, "Le code ne peut contenir que des lettres (sans accent) et des chiffres.")
        return;
      end
    end
  end
end
