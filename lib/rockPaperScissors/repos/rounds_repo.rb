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

    def self.save db, round_data
      if round_data['id']
        # Update Winner
        if round_data['winner_id']
          sql = %q[UPDATE rounds SET winner_id = $2 WHERE id = $1 RETURNING *]
          db.exec(sql, [round_data['id'], round_data['winner_id']])
        end
        if round_data['host_choice']
          sql = %q[UPDATE rounds SET host_choice = $2 WHERE id = $1 RETURNING *]
          db.exec(sql, [round_data['id'], round_data['host_choice']])
        end
        if round_data['guest_choice']
          sql = %q[UPDATE rounds SET guest_choice = $2 WHERE id = $1 RETURNING *]
          db.exec(sql, [round_data['id'], round_data['guest_choice']])
        end
        find(db, round_data['id'])
      else
        sql = %q[INSERT INTO rounds (match_id) VALUES ($1, $2) RETURNING *]
        db.exec(sql, [round_data['host_id'], round_data['guest_id']]).entries.first
      end
    end

  end
end