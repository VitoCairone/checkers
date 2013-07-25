#encoding : UTF-8

# Vito Cairone

require 'colorize'

class InvalidMoveError < StandardError
end

class Board
  attr_accessor :squares

  def at(position)
    @squares[position[1]][position[0]]
  end

  def dup
    board = Board.new(false)
    board.squares = @squares.map do |row|
      row.map { |piece| piece.nil? ? nil : piece.dup(board) }
    end
    board
  end

  def initialize(should_setup = true)
    @squares = Array.new(8) { Array.new(8) { nil } }
    setup if should_setup
  end

  def player_can_jump?(color)
    @squares.any? do |row|
      row.any? do |piece|
        !piece.nil? && (piece.color == color && !piece.jump_moves.empty?)
      end
    end
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

    red_start = [[1,7],[3,7],[5,7],[7,7]]
    red_start += [[0,6],[2,6],[4,6],[6,6]]
    red_start += [[1,5],[3,5],[5,5],[7,5]]
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
        print "Enter move, e.g. a6 b5: "
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
        begin
          piece.perform_moves!([move_to])
          player_color = Board.opp_color(player_color)
        rescue InvalidMoveError
          print "#{input[0..1].join("")} to #{input[-2..-1].join("")}"
          puts " is not a valid move."
        end
        #status = :over if (game_won?)
      else
        puts "Cannot move the enemy's pieces."
      end #end if piece.move
    end #end while loop
  end

  def inspect
    "Board \##{self.object_id}"
  end

  def occupied?(position)
    !unoccupied?(position)
  end

  def unoccupied?(position)
    at(position).nil?
  end

  def self.in_bounds?(position)
    position.all? { |idx| idx.between?(0,7) }
  end

end

class Piece
  attr_accessor :color, :king, :board, :position

  def self.add_delta(pos, delta)
    [ pos[0] + delta[0], pos[1] + delta[1] ]
  end

  def self.between_position(jumpoff, landing)
    [ (jumpoff[0] + landing[0]) / 2, (jumpoff[1] + landing[1]) / 2]
  end

  def self.double_delta(delta)
    delta.map { |i| 2 * i }
  end

  def dup(board)
    duplicate = Piece.new(self.color, board, self.position)
    duplicate.king = self.king
    duplicate
  end

  def initialize(color, board, position)
    @color = color
    @king = false
    @board = board
    @position = position
  end

  def single_diags
    if self.king
      [[1, 1], [1, -1], [-1, 1], [-1, -1]]
    elsif self.color == :black
      [[-1, 1], [1, 1]]
    else
      [[-1, -1], [1, -1]]
    end
  end

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
    moves = single_diags.map { |delta| Piece.add_delta(cur_pos, delta) }
    moves.select { |pos| Board.in_bounds?(pos) && @board.unoccupied?(pos) }
  end

  def jump_moves
    jump_moves = []
    single_diags.each do |delta|
      jump_over = Piece.add_delta(self.position, delta)
      landing = Piece.add_delta(self.position, Piece.double_delta(delta))

      next unless Board.in_bounds?(landing)

      if enemy_piece?(jump_over) && @board.unoccupied?(landing)
        jump_moves << landing
      end
    end
    jump_moves
  end

  def perform_slide(new_position)
    raise InvalidMoveError unless slide_moves.include?(new_position)
    @board.set_at(self.position, nil)
    @board.set_at(new_position, self)
    self.position = new_position
  end

  def perform_jump(new_position)
    #perform_jump should remove the jumped pieces from the Board
    #an illegal slide/jump should raise InvalidMoveError
    raise InvalidMoveError unless jump_moves.include?(new_position)
    remove_from = between_position(self.position, new_position)
    @board.set_at(self.position, nil)
    @board.set_at(remove_from, nil)
    @board.set_at(new_position, self)
    self.position = new_position
  end

  def perform_moves!(move_seq)
    #move_sequence is one slide, or one or more jumps
    #should perform moves one by one
    #if a move fails, raise InvalidMoveError
    #don't bother to try to restore original Board state
    moves_remaining = move_seq.dup
    moved_once = false
    can_jump = @board.player_can_jump?(self.color)

    if can_jump
      until moves_remaining.empty?
        next_position = moves_remaining.shift

        possible_moves = jump_moves
        unless (possible_moves.empty?)
          raise InvalidMoveError unless possible_moves.include?(next_position)
          perform_jump(next_position)
          moved_once = true
          next
        end

        raise InvalidMoveError if (moved_once || can_jump)

        possible_moves = slide_moves
        raise InvalidMoveError unless possible_moves.include?(next_position)
        perform_slide(next_position)
        moved_once = true
      end
    else
      #slide stuff here
    end
  end

  def valid_move_seq?(move_seq)
    #should call perform_moves! on a duped Piece/Board
    #return true if no error is raised, else false
    #should not modify the original Board
    test_board = @board.dup
    equiv_piece = test_board.at(self.position)
    begin
      equiv_piece.perform_moves!(move_seq)
    rescue
      return false
    end
    true
  end

  def perform_moves(move_seq)
    #check valid_move_seq?, then either call peform_moves!
    #  or raise InvalidMoveError
    raise InvalidMoveError unless valid_move_seq?(move_seq)
    perform_moves!(move_seq)
  end

  def to_s
    #" ● ".colorize(self.color) # 'Filled Circle'
    ((self.king) ? " ♚ " : " ◉ ").colorize(self.color) # 'Fisheye'
  end
end