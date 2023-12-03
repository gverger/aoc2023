# frozen_string_literal: true

lines = File.readlines('./input.txt')

class Parser
  def initialize(extractor)
    @extractor = extractor
  end

  def extracted_number(line)
    e = @extractor.new(line)
    value = e.first_number * 10 + e.last_number
    puts line + ' => ' + value.to_s
    value
  end
end

class Part1
  def initialize(line)
    @line = line
  end

  def first_number
    @line.chars.find { |c| digit? c }.to_i
  end

  def last_number
    @line.chars.reverse.find { |c| digit? c }.to_i
  end

  private

  def digit?(char)
    char >= '0' && char <= '9'
  end
end

class Part2
  NUMBERS = {
    '1' => 1,
    '2' => 2,
    '3' => 3,
    '4' => 4,
    '5' => 5,
    '6' => 6,
    '7' => 7,
    '8' => 8,
    '9' => 9,
    'one' => 1,
    'two' => 2,
    'three' => 3,
    'four' => 4,
    'five' => 5,
    'six' => 6,
    'seven' => 7,
    'eight' => 8,
    'nine' => 9
  }.freeze

  def initialize(line)
    @line = line
  end

  def first_number
    NUMBERS.map { |k, v| IdxNumber.new(v, @line.index(k)) }.select(&:exists?).min_by(&:index).value
  end

  def last_number
    NUMBERS.map { |k, v| IdxNumber.new(v, @line.rindex(k)) }.select(&:exists?).max_by(&:index).value
  end
end

IdxNumber = Struct.new(:value, :index) do
  def exists?
    !index.nil?
  end
end

# parser = Parser.new(Part1)
parser = Parser.new(Part2)
puts(lines.sum { |line| parser.extracted_number(line) })
