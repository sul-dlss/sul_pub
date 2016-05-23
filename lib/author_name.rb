##
# Author name used in PubHash to construct CSL authors
class AuthorName
  attr_reader :last, :first, :middle

  # @param author [Hash] with keys :firstname, :middlename, :lastname
  def initialize(author)
    @first = as_string author[:firstname]
    @middle = as_string author[:middlename]
    @last = as_string author[:lastname]
  end

  def first_initial
    @first_initial ||= initial(first)
  end

  def first_name
    @first_name ||= first.length == 1 ? "#{first_initial}." : first
  end

  def middle_initial
    @middle_initial ||= initial(middle)
  end

  def middle_name
    @middle_name ||= middle.length == 1 ? "#{middle_initial}." : middle
  end

  def family_name
    last
  end

  def given_name
    @given_name ||= "#{first_name} #{middle_name}".strip
  end

  def to_csl_author
    @csl_author ||= { 'family' => family_name, 'given' => given_name }
  end

  def ==(other)
    last == other.last &&
    first == other.first &&
    middle == other.middle
  end

  protected

    def as_string(param)
      param.to_s.strip
    end

    def initial(name)
      name[0].to_s.upcase
    end
end
