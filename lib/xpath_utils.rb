class XpathUtils
  def regex_reject(node_set, regex)
    node_set.reject { |node| node.text =~ /^(#{regex})$/i }
  end
end
