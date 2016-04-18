module SuggestionQueries
  def journal_doc_email_and_seed
    <<-xml.strip_heredoc.gsub(/\n$/, '')
      <?xml version='1.0'?>
            <PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
              <Authors>
                <Author>
                  <LastName>Doe</LastName>
                  <FirstName>John</FirstName>
                  <MiddleName>S</MiddleName>
                  <City>Stanford</City>
                  <State>CA</State>
                  <Country>USA</Country>
                  <Version>1</Version>
               </Author>
            </Authors>
            <DocumentCategory>Journal Document</DocumentCategory>
            <Emails>
                        <string>johnsdoe@example.com</string>
                      </Emails><PublicationItemIds><int>532237</int></PublicationItemIds><LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly></PublicationAuthorMatchParameters>
    xml
  end

  def conf_proc_doc_email_and_seed
    <<-xml.strip_heredoc.gsub(/\n$/, '')
      <?xml version='1.0'?>
            <PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
              <Authors>
                <Author>
                  <LastName>Doe</LastName>
                  <FirstName>John</FirstName>
                  <MiddleName>S</MiddleName>
                  <City>Stanford</City>
                  <State>CA</State>
                  <Country>USA</Country>
                  <Version>1</Version>
               </Author>
            </Authors>
            <DocumentCategory>Conference Proceeding Document</DocumentCategory>
            <Emails>
                        <string>johnsdoe@example.com</string>
                      </Emails><PublicationItemIds><int>532237</int></PublicationItemIds><LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly></PublicationAuthorMatchParameters>
    xml
  end

  def journal_doc_email_no_seed
    <<-xml.strip_heredoc.gsub(/\n$/, '')
      <?xml version='1.0'?>
            <PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
              <Authors>
                <Author>
                  <LastName>Smith</LastName>
                  <FirstName>Jane</FirstName>
                  <MiddleName></MiddleName>
                  <City>Stanford</City>
                  <State>CA</State>
                  <Country>USA</Country>
                  <Version>1</Version>
               </Author>
            </Authors>
            <DocumentCategory>Journal Document</DocumentCategory>
            <Emails>
                        <string>jane_smith@example.com</string>
                      </Emails><LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly></PublicationAuthorMatchParameters>
    xml
  end

  def conf_proc_doc_email_no_seed
    <<-xml.strip_heredoc.gsub(/\n$/, '')
      <?xml version='1.0'?>
            <PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
              <Authors>
                <Author>
                  <LastName>Smith</LastName>
                  <FirstName>Jane</FirstName>
                  <MiddleName></MiddleName>
                  <City>Stanford</City>
                  <State>CA</State>
                  <Country>USA</Country>
                  <Version>1</Version>
               </Author>
            </Authors>
            <DocumentCategory>Conference Proceeding Document</DocumentCategory>
            <Emails>
                        <string>jane_smith@example.com</string>
                      </Emails><LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly></PublicationAuthorMatchParameters>
    xml
  end

  def journal_doc_no_email_no_seed
    <<-xml.strip_heredoc.gsub(/\n$/, '')
      <?xml version='1.0'?>
            <PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
              <Authors>
                <Author>
                  <LastName>Brown</LastName>
                  <FirstName>Charlie</FirstName>
                  <MiddleName></MiddleName>
                  <City>Stanford</City>
                  <State>CA</State>
                  <Country>USA</Country>
                  <Version>1</Version>
               </Author>
            </Authors>
            <DocumentCategory>Journal Document</DocumentCategory>
            <LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly></PublicationAuthorMatchParameters>
    xml
  end

  def conf_proc_doc_no_email_no_seed
    <<-xml.strip_heredoc.gsub(/\n$/, '')
      <?xml version='1.0'?>
            <PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
              <Authors>
                <Author>
                  <LastName>Brown</LastName>
                  <FirstName>Charlie</FirstName>
                  <MiddleName></MiddleName>
                  <City>Stanford</City>
                  <State>CA</State>
                  <Country>USA</Country>
                  <Version>1</Version>
               </Author>
            </Authors>
            <DocumentCategory>Conference Proceeding Document</DocumentCategory>
            <LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly></PublicationAuthorMatchParameters>
    xml
  end
end
