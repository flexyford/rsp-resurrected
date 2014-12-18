module RockPaperScissors
  class MatchesRepo
    def self.find db, match_id
      sql = %q[SELECT * FROM matches WHERE id = $1]
      result = db.exec(sql, [match_id])
      result.first
    end

    def self.find_active_by_user db, user_id
      # An array of hashes, where each hash has all the data for that match
      sql =<<-SQL
        SELECT * FROM matches where (host_id = $1 or guest_id = $1) 
        and winner_id IS NULL
      SQL
      db.exec(sql, [user_id]).entries
    end


    def self.find_by_user db, user_id
      # An array of hashes, where each hash has all the data for that match  
      sql =<<-SQL 
        SELECT * FROM matches where host_id = $1 or guest_id = $1
       SQL
      db.exec(sql, [user_id]).entries
    end

    def self.save db match_data
        sql =<<-SQL 
        INSERT INTO matches (host_id, guest_id) values ($1, $2)
        SQL
        db.exec(sql, [match_data['host_id'], match_data['guest_id']]).entries
    end

  end
end