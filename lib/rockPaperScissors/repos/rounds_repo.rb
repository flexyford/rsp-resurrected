module RockPaperScissors
  class RoundsRepo
    def self.find db, round_id
      sql = %q[SELECT * FROM rounds WHERE id = $1]
      result = db.exec(sql, [round_id])
      result.first
    end
  end
end