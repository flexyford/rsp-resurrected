module RockPaperScissors
  class UsersRepo
    def self.find db, user_id
      sql = %q[SELECT * FROM users WHERE id = $1]
      result = db.exec(sql, [user_id])
      result.first
    end

    def self.user_record db, user_id
      # Table which has win, loss, draw columns with counts to idicate the user's overall record
    end
  end
end