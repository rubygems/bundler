require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "The library itself" do

  # match do |filename|
  #   @failing_lines = []
  #   File.readlines(filename).each_with_index do |line,number|
  #     @failing_lines << number + 1 if line =~ /\t/
  #   end
  #   @failing_lines.empty?
  # end
  #
  # failure_message_for_should do |filename|
  #   "The file #{filename} has tab characters on lines #{@failing_lines.join(', ')}"
  # end
  def check_for_tab_characters(filename)
    failing_lines = []
    File.readlines(filename).each_with_index do |line,number|
      failing_lines << number + 1 if line =~ /\t/
    end

    unless failing_lines.empty?
      "#{filename} has tab characters on lines #{failing_lines.join(', ')}"
    end
  end

  def check_for_extra_spaces(filename)
    failing_lines = []
    File.readlines(filename).each_with_index do |line,number|
      next if line =~ /^\s+#.*\s+\n$/
      failing_lines << number + 1 if line =~ /\s+\n$/
    end

    unless failing_lines.empty?
      "#{filename} has spaces on the EOL on lines #{failing_lines.join(', ')}"
    end
  end

  def be_well_formed
    simple_matcher("be well formed") do |given, matcher|
      matcher.failure_message = given.join("\n")
      given.empty?
    end
  end

  it "has no malformed whitespace" do
    error_messages = []
    Dir.chdir(File.dirname(__FILE__) + '/..') do
      `git ls-files`.split("\n").each do |filename|
        next if filename =~ /\.gitmodules|fixtures/
        error_messages << check_for_tab_characters(filename)
        error_messages << check_for_extra_spaces(filename)
      end
    end
    error_messages.compact.should be_well_formed
  end
end
