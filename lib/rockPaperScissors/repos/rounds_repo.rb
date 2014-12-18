require 'pg'

module RockPaperScissors
  class RoundsRepo

    def self.all(db)
      db.exec("SELECT * FROM rounds").to_a
    end

    def self.find db, round_id
      sql = %q[SELECT * FROM rounds WHERE id = $1]
      result = db.exec(sql, [round_id])
      result.first
    end

    def self.find_active_by_user db, user_id
      sql = %q[ SELECT * from rounds r 
        join matches m 
        on m.id = r.match_id 
        where (host_id = $1 or guest_id = $1)
        and (host_choice is null or guest_choice is null)]
        db.exec(sql,[user_id])
    end

    def self.find_active_by_match db, match_id
      sql = %q[SELECT * FROM rounds WHERE match_id = $1 
        and (host_choice is null or guest_choice is null)]
      db.exec(sql, [match_id]).entries
    end

    def self.find_by_user db, user_id
      sql = %q[ SELECT * from rounds r 
        join matches m 
        on m.id = r.match_id 
        where (host_id = $1 or guest_id = $1)
      ]
      db.exec(sql,[user_id])
    end

    def self.find_by_match db, match_id
      sql = %q[SELECT * FROM rounds WHERE match_id = $1]
      db.exec(sql, [match_id]).entries
    end

    def self.save db, match_data
      #new empty round
      #update player choice
      #set round winner
    end

  end
end