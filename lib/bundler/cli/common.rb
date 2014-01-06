module Bundler
  module CLI::Common
    def self.without_groups_message
      groups = Bundler.settings.without
      group_list = [groups[0...-1].join(", "), groups[-1..-1]].
        reject{|s| s.to_s.empty? }.join(" and ")
      group_str = (groups.size == 1) ? "group" : "groups"
      "Gems in the #{group_str} #{group_list} were not installed."
    end
  end
end
