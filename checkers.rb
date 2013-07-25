#encoding : UTF-8

# Vito Cairone

require 'colorize'

class Board
  attr_accessor :squares

  def at(position)
    @squares[position[1]][position[0]]
  end

  def initialize(should_setup = true)
    @squares = Array.new(8) { Array.new(8) { nil } }
    setup if should_setup
  end

  def self.opp_color(color)
    (color == :black) ? :red : :black
  end

  def set_at(position, piece)
    @squares[position[1]][position[0]] = piece
  end

  def setup
    black_start = [[0,0],[2,0],[4,0],[6,0]]
    black_start += [[1,1],[3,1],[5,1],[7,1]]
    black_start += [[0,2],[2,2],[4,2],[6,2]]
    black_start.each { |pos| set_at(pos, Piece.new(:black, self, pos)) }

    red_start = [[0,7],[2,7],[4,7],[6,7]]
    red_start += [[1,6],[3,6],[5,6],[7,6]]
    red_start += [[0,5],[2,5],[4,5],[6,5]]
    red_start.each { |pos| set_at(pos, Piece.new(:red, self, pos)) }
  end

  def to_s
    dark = true
    header = ('a'..'h').to_a.join("  ")
    row_index = 9
    body = self.squares.map do |row|
      row_str = row.map do |space|
        dark = !dark
        back_color = dark ? :blue: :cyan
        (space.nil? ? "   " : space.to_s).colorize(:background => back_color)
      end.join("")
      dark = !dark
      "#{(row_index -= 1)} #{row_str}"
    end.join("\n")
    "   #{header} \n#{body}"
  end

  def run
    player_color = :black
    ltr_hash = {}
    numchr_hash = {}
    ("a".."h").to_a.each_with_index { |ltr, idx| ltr_hash[ltr] = idx }
    ("1".."8").to_a.reverse.each_with_index do |numchr, idx|
      numchr_hash[numchr] = idx
    end
    status = :play
    while status == :play
      puts self.to_s
      begin
        print "#{player_color.to_s.capitalize}'s turn. "
        print "Enter move, e.g. b8 c6: "
        input = gets.chomp.split("")
        move_from = [ ltr_hash[input[0]], numchr_hash[input[1]] ]
        move_to = [ ltr_hash[input[-2]], numchr_hash[input[-1]] ]
        piece = at(move_from)
        raise if piece.nil?
      rescue
        puts "There is no piece at #{move_from[0]},#{move_from[1]}"
        retry
      end
      if piece.color == player_color
        piece.perform_slide(move_to)
        #status = :over if (game_won?)
        player_color = Board.opp_color(player_color)
      else
        puts "Cannot move the enemy's pieces."
      end #end if piece.move
    end #end while loop
  end

  def inspect
  end


  def occupied?(position)
    !unoccupied?(position)
  end
  
  def unoccupied?(position)
    at(position).nil?
  end

  def in_bounds?(position)
    position.all? { |idx| idx.between?(0,7) }
  end

end

class Piece
  attr_accessor :color, :king, :board, :position

  def apply_delta(pos, delta)
    [ pos[0] + delta[0], pos[1] + delta[1] ]
  end
  
  def double_delta(delta)
    delta.map { |i| 2 * i }
  end
  
  def initialize(color, board, position)
    @color = color
    @king = false
    @board = board
    @position = position
  end

  SINGLE_DIAGS = [
    [-1, -1],
    [ 1, -1],
    [-1,  1],
    [ 1,  1]
  ]

  DOUBLE_DIAGS = [
    [-2, -2],
    [ 2, -2],
    [-2,  2],
    [ 2,  2]
  ]

  def ally_piece?(position)
    @board.occupied?(position) && same_color?(position)
  end

  def enemy_piece?(position)
    @board.occupied?(position) && !same_color?(position)
  end
  
  def same_color?(position)
    #expects a position which is in-bounds and occupied
    @board.at(position).color == self.color
  end
  
  def slide_moves
    cur_pos = self.position
    moves = SINGLE_DIAGS.map { |delta| apply_delta(cur_pos, delta) }
    moves.select { |pos| @board.in_bounds?(pos) && @board.unoccupied?(pos) }
  end

  def jump_moves
    jump_moves = []
    SINGLE_DIAGS.each do |delta|
      jump_over = apply_delta(self.position, delta)
      landing = apply_delta(self.position, double_delta(delta))
      next unless @board.in_bounds?(landing)
      if enemy_piece?(jump_over) && @board.unoccupied?(landing)
        jump_moves << [jump_over, landing]
      end
    end
    jump_moves
  end

  #execute_move is the 'innermost' utility function. All validity checks should
  #be performed BEFORE calling execute_move.
  def execute_move(new_position)
    @board.set_at(self.position, nil)
    @board.set_at(new_position, self)
    self.position = new_position
  end

  def perform_slide(position)
    raise InvalidMoveError unless slide_moves.include?(position)
    execute_move(position)
  end

  def perform_jump
    #perform_jump should remove the jumped pieces from the Board
    #an illegal slide/jump should raise InvalidMoveError
    raise InvalidMoveError
  end

  def perform_moves!(move_sequence)
    #move_sequence is one slide, or one or more jumps
    #should perform moves one by one
    #if a move fails, raise InvalidMoveError
    #don't bother to try to restore original Board state
    raise InvalidMoveError
  end

  def valid_move_seq?
    #should call perform_moves! on a duped Piece/Board
    #return true if no error is raised, else false
    #should not modify the original Board
  end

  def perform_moves
    #check valid_move_seq?, then either call peform_moves!
    #  or raise InvalidMoveError
    raise InvalidMoveError
  end

  def to_s
    #" ● ".colorize(self.color) # 'Filled Circle'
    ((self.king) ? " ♚ " : " ◉ ").colorize(self.color) # 'Fisheye'
  end
end