require 'pg'
require 'pry-byebug'

module RockPaperScissors
  class MatchesRepo

    def self.all(db)
      db.exec("SELECT * FROM matches").to_a
    end

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


    def self.save db, match_data

      if match_data['id']
        # Update Winner
        if match_data['winner_id']
          sql = %q[UPDATE matches SET winner_id = $2 WHERE id = $1 RETURNING *]
          db.exec(sql, [match_data['id'], match_data['winner_id']])
        end
        find(db, match_data['id'])
      else
        sql = %q[INSERT INTO matches (host_id, guest_id) VALUES ($1, $2) RETURNING *]
        db.exec(sql, [match_data['host_id'], match_data['guest_id']]).entries.first
      end
    end

  end
end