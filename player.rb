class MustOverrideError < StandardError
end

class Player
  attr_accessor :board, :color

  def initialize(color, board)
    self.color = color
    self.board = board
  end

  def pick_move
    raise MustOverrideError
  end
end

class HumanPlayer < Player

  def pick_move
    print "Enter move: "
    input = gets.chomp.split(" ")

    return [nil, nil] if ["quit","q","QUIT","Q","exit"].include?(input.first)

    move_from = parse_input(input.shift)
    move_to = input.map { |str| parse_input(str) }
    [move_from, move_to]
  end

  def parse_input(input_str)
    ltr_hash = {}
    numchr_hash = {}
    ("a".."h").to_a.each_with_index { |ltr, idx| ltr_hash[ltr] = idx }
    ("1".."8").to_a.reverse.each_with_index do |numchr, idx|
      numchr_hash[numchr] = idx
    end
    [ ltr_hash[input_str[0]], numchr_hash[input_str[1]] ]
  end

  def self.print_instructions
    puts "HOW TO PLAY:"
    puts "Enter a move as a 'to' and 'from' position with a space between,"
    puts "for example: c6 d7"
    puts "To make a multiple-jump, include all destinations,"
    puts "for example: h8 f6 h4 f2"
  end

end

class ComputerPlayer < Player

  def jump_sequence(piece, jump_to)
    jump_seq = [jump_to]
    test_board = self.board.dup
    equiv_piece = test_board.at(piece.position)
    equiv_piece.perform_jump(jump_to)
    while !(equiv_piece.jump_moves.empty?)
      next_jump = equiv_piece.jump_moves.sample
      jump_seq << next_jump
      equiv_piece.perform_jump(next_jump)
    end
    jump_seq
  end

  def my_piece(piece)
    !piece.nil? && piece.color == self.color
  end

  def pick_move

    sleep(1)
    puts "\n" #since the human player makes a new line, the computer does too

    my_pieces = []
    my_piece = nil
    my_move_to = nil

    if self.board.player_can_jump?(self.color)

      self.board.squares.each do |row|
        row.each do |piece|
          my_pieces << piece if my_piece(piece) && !piece.jump_moves.empty?
        end
      end

      my_piece = my_pieces.sample
      my_move_to = jump_sequence(my_piece, my_piece.jump_moves.sample)

    else

      self.board.squares.each do |row|
        row.each do |piece|
          my_pieces << piece if my_piece(piece) && !piece.slide_moves.empty?
        end
      end

      my_piece = my_pieces.sample
      my_move_to = [my_piece.slide_moves.sample]

    end

    [my_piece.position, my_move_to]

  end

end