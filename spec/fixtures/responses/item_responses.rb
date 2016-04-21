module ItemResponses
  def publication_item_responses
    <<-XML.strip_heredoc
    <?xml version="1.0"?>
    <ArrayOfItemMatchResult xmlns:xsd="http://www.w3.org/2001/XMLSchema"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <ItemMatchResult>
        <MatchRank>1</MatchRank>
        <PublicationItemID>29352378</PublicationItemID>
        <MatchScore>1.2708333730697632</MatchScore>
      </ItemMatchResult>
      <ItemMatchResult>
        <MatchRank>2</MatchRank>
        <PublicationItemID>29187981</PublicationItemID>
        <MatchScore>0.992100179195404</MatchScore>
      </ItemMatchResult>
      <ItemMatchResult>
        <MatchRank>3</MatchRank>
        <PublicationItemID>46795732</PublicationItemID>
        <MatchScore>0.519425094127655</MatchScore>
      </ItemMatchResult>
      <ItemMatchResult>
        <MatchRank>4</MatchRank>
        <PublicationItemID>47593787</PublicationItemID>
        <MatchScore>0.49828395247459412</MatchScore>
      </ItemMatchResult>
    </ArrayOfItemMatchResult>
    XML
  end
end
