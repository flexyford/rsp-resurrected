module RockPaperScissors
  class RoundsRepo
    def self.find db, round_id
      sql = %q[SELECT * FROM rounds WHERE id = $1]
      result = db.exec(sql, [round_id])
      result.first
    end

    def self.find_active_by_user db, user_id

    end

    def self.find_active_by_match db, match_id

    end

    def self.find_by_user db, user_id
      
    end

    def self.find_by_match db, match_id
      
    end

    def self.save db match_data

    end

  end
end