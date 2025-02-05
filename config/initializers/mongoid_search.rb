Mongoid::Search.setup do |config|
  ## Default matching type. Match :any or :all searched keywords
  config.match = :all

  ## If true, an empty search will return all objects
  config.allow_empty_search = true

  ## If true, will search with relevance information
  config.relevant_search = false

  ## Stem keywords
  config.stem_keywords = false

  ## Add a custom proc returning strings to replace the default stemmer
  # For example using ruby-stemmer:
  # config.stem_proc = Proc.new { |word| Lingua.stemmer(word, :language => 'nl') }

  # search such as 2017-10-08 might result in a "2017 10 08" one
  # we can trim characters beforehand to avoid this issue
  config.trim_characters = ['-']

  ## Words to ignore
  config.ignore_list = []

  ## An array of words
  # config.ignore_list = %w{ a an to from as }

  ## Or from a file
  # config.ignore_list = YAML.load(File.open(File.dirname(__FILE__) + '/config/ignorelist.yml'))['ignorelist']

  ## Search using regex (slower)
  config.regex_search = true

  ## Regex to search

  ## Match partial words on both sides (slower)
  config.regex = Proc.new { |query| /#{query}/ }

  ## Match partial words on the beginning or in the end (slightly faster)
  # config.regex = Proc.new { |query| /^#{query}/ }
  # config.regex = Proc.new { |query| /#{query}$/ }

  # Ligatures to be replaced
  # http://en.wikipedia.org/wiki/Typographic_ligature
  config.ligatures = { 'œ' => 'oe', 'æ' => 'ae' }

  # Minimum word size. Words smaller than it won't be indexed
  config.minimum_word_size = 0
end
