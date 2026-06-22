class AddCanonicalEmailToUsers < ActiveRecord::Migration[7.1]
  # See issue #108: to make the creation of double accounts harder, we store a
  # "canonical" version of each e-mail address (see User.canonical_email) and we
  # forbid a new account whose canonical address is already used by another one.
  #
  # The index is voluntarily NOT unique: the current database may already contain
  # such near-duplicates, and cleaning them up is out of the scope of this
  # migration. The (non-unique) index still makes it cheap to:
  #   * validate each new account, and
  #   * list the already existing duplicates, for instance with:
  #       SELECT canonical_email, COUNT(*) FROM users
  #       GROUP BY canonical_email HAVING COUNT(*) > 1;
  # Once those duplicates have been dealt with, the index could be made unique.
  def up
    add_column :users, :canonical_email, :string
    add_index :users, :canonical_email

    # Backfill existing users. We reuse User.canonical_email (a pure function that
    # does not touch the database) so that the canonicalization logic stays
    # defined in a single place. update_column skips validations and callbacks,
    # which is exactly what we want here (and the users table has no updated_at).
    User.reset_column_information
    User.find_each do |user|
      user.update_column(:canonical_email, User.canonical_email(user.email))
    end
  end

  def down
    remove_index :users, :canonical_email
    remove_column :users, :canonical_email
  end
end
