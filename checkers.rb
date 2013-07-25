class Board
  attr_accessor :squares

  def initialize
    @squares = Array.new(8) { Array.new(8) { nil } }
  end
end

class Piece
  attr_accessor :color, :king, :board

  def initialize(color, board)
    @color = color
    @king = false
    @board = board
  end

  def slide_moves
  end

  def jump_moves
  end

  def perform_slide
  end

  def perform_jump
    #perform_jump should remove the jumped pieces from the Board
    #an illegal slide/jump should raise InvalidMoveError
  end

  def perform_moves!(move_sequence)
    #move_sequence is one slide, or one or more jumps
    #should perform moves one by one
    #if a move fails, raise InvalidMoveError
    #don't bother to try to restore original Board state
  end

  def valid_move_seq?
    #should call perform_moves! on a duped Piece/Board
    #return true if no error is raised, else false
    #should not modify the original Board
  end

  def perform_moves
    #check valid_move_seq?, then either call peform_moves!
    #  or raise InvalidMoveError
  end
end