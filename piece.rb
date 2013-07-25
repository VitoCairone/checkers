#encoding : UTF-8

class Piece
  attr_accessor :color, :king, :board, :position

  def ally_piece?(position)
    @board.occupied?(position) && same_color?(position)
  end

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

  def enemy_piece?(position)
    @board.occupied?(position) && !same_color?(position)
  end

  def initialize(color, board, position)
    @color = color
    @king = false
    @board = board
    @position = position
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

  def perform_jump(new_position)
    #perform_jump should remove the jumped pieces from the Board
    #an illegal slide/jump should raise InvalidMoveError
    raise InvalidMoveError unless jump_moves.include?(new_position)
    remove_from = Piece.between_position(self.position, new_position)
    @board.set_at(self.position, nil)
    @board.set_at(remove_from, nil)
    @board.set_at(new_position, self)
    self.position = new_position
  end

  def perform_moves(move_seq)
    #check valid_move_seq?, then either call peform_moves!
    #  or raise InvalidMoveError
    raise InvalidMoveError unless valid_move_seq?(move_seq)
    perform_moves!(move_seq)
  end

  def perform_moves!(move_seq)
    #move_sequence is one slide, or one or more jumps
    #should perform moves one by one
    #if a move fails, raise InvalidMoveError
    #don't bother to try to restore original Board state
    if @board.player_can_jump?(self.color)

      #jump stuff here
      moves_remaining = move_seq.dup
      until moves_remaining.empty?
        next_position = moves_remaining.shift
        raise InvalidMoveError unless jump_moves.include?(next_position)
        perform_jump(next_position)
      end
      raise InvalidMoveError unless jump_moves.empty?

    else

      #slide stuff here
      next_position = move_seq.first
      raise InvalidMoveError unless slide_moves.include?(next_position)
      perform_slide(next_position)

    end

    self.king = true if (reached_back_row && !self.king)
  end

  def perform_slide(new_position)
    raise InvalidMoveError unless slide_moves.include?(new_position)
    @board.set_at(self.position, nil)
    @board.set_at(new_position, self)
    self.position = new_position
  end

  def reached_back_row
    self.position[1] == (self.color == :red ? 0 : 7)
  end

  def same_color?(position)
    #expects a position which is in-bounds and occupied
    @board.at(position).color == self.color
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

  def slide_moves
    cur_pos = self.position
    moves = single_diags.map { |delta| Piece.add_delta(cur_pos, delta) }
    moves.select { |pos| Board.in_bounds?(pos) && @board.unoccupied?(pos) }
  end

  #For UTF characters see http://www.csbruce.com/software/utf-8.html
  def to_s
    ((self.king) ? " ♚ " : " ◉ ").colorize(self.color)
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

end