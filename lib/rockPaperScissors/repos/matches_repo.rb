module RockPaperScissors
  class MatchesRepo
    def self.find db, match_id
      sql = %q[SELECT * FROM matches WHERE id = $1]
      result = db.exec(sql, [match_id])
      result.first
    end

    def self.find_active_by_user db, user_id
      # An array of hashes, where each hash has all the data for that match
    end

    def self.find_by_user db, user_id
      # An array of hashes, where each hash has all the data for that match  
    end

    def self.save db match_data

    end


  end
end