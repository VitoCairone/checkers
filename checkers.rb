#encoding : UTF-8

# Vito Cairone

require 'colorize'
require_relative 'piece.rb'
require_relative 'player.rb'

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

  def get_move(player)
    #Get a move and ensure it is valid
    begin
      print "#{player.color.capitalize}'s turn. "
      move_from, move_to = player.pick_move
      return [nil, nil] if move_from.nil? #indicates QUIT option

      piece = at(move_from)
      raise if piece.nil? || piece.color != player.color
    rescue
      puts "Cannot move from #{unparse_position(move_from)}"
      retry
    end
    [piece, move_to]
  end

  def self.in_bounds?(position)
    position.all? { |idx| idx.between?(0,7) }
  end

  def initialize(should_setup = true)
    @squares = Array.new(8) { Array.new(8) { nil } }
    setup if should_setup
  end

  def inspect
    "Board \##{self.object_id}"
  end

  def self.opp_color(color)
    (color == :black) ? :red : :black
  end

  def occupied?(position)
    !unoccupied?(position)
  end

  def player_can_jump?(color)
    @squares.any? do |row|
      row.any? do |piece|
        !piece.nil? && (piece.color == color && !piece.jump_moves.empty?)
      end
    end
  end

  def run(player1 = nil, player2 = nil)
    player1 = HumanPlayer.new(:black, self) if player1.nil?
    player2 = ComputerPlayer.new(:red, self) if player2.nil?

    raise RuntimeError if player1 == player2
    raise RuntimeError if player1.color == player2.color

    if player1.is_a?(HumanPlayer) || player2.is_a?(HumanPlayer)
      HumanPlayer.print_instructions
    end

    cur_player = player1
    self.show
    while true
      piece, move_to = get_move(cur_player)
      return if piece.nil? #pass through QUIT option

      begin
        piece.perform_moves(move_to)
        if won?(cur_player.color)
          puts "#{cur_player.color.capitalize} wins!"
          return
        end
        cur_player = (cur_player == player1 ? player2 : player1)
      rescue InvalidMoveError
        puts "Invalid move. Try again."
      else
        self.show
      end
    end #end while loop
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

  def show
    puts self.to_s
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

  def unoccupied?(position)
    at(position).nil?
  end

  def unparse_position(position)
    i, j = position
    "#{("a".."h").to_a[i]}#{("1".."8").to_a.reverse[j]}"
  end

  def won?(color)
    enemy_color = Board.opp_color(color)
    !@squares.any? do |row|
      row.any? { |piece| !piece.nil? && (piece.color == enemy_color) }
    end
  end

end