module WebOfScience

  # Map WOS record abstract data into the SUL PubHash data
  class MapMesh < Mapper

    # @return [Array<String>]
    def mesh
      mesh_headings.map do |mesh_heading|
        {
          'descriptor' => mesh_descriptors(mesh_heading),
          'qualifier' => mesh_qualifiers(mesh_heading),
          'treecode' => mesh_treecodes(mesh_heading)
        }
      end
    end

    private

      # publication abstract details
      # @return [Hash]
      def mapper
        mesh.empty? ? {} : { mesh_headings: mesh.map(&:deep_symbolize_keys) }
      end

      # @return [Nokogiri::XML::NodeSet]
      def mesh_headings
        # Note: rec.doc.xpath(nil).map(&:text) => []
        rec.doc.xpath(path)
      end

      # @param [Nokogiri::XML::Element] mesh_heading
      # @return [Hash]
      def mesh_descriptors(mesh_heading)
        mesh_heading.search('DescriptorName').map { |descriptor| mesh_element(descriptor) }
      end

      # @param [Nokogiri::XML::Element] mesh_heading
      # @return [Hash]
      def mesh_qualifiers(mesh_heading)
        mesh_heading.search('QualifierName').map { |qualifier| mesh_element(qualifier) }
      end

      # @param [Nokogiri::XML::Element] mesh_heading
      # @return [Hash]
      def mesh_treecodes(mesh_heading)
        mesh_heading.search('TreeCode').map do |code|
          { 'code' => code.text, 'major' => code['MajorTopicYN'] }
        end
      end

      # @param [Nokogiri::XML::Element] element
      # @return [Hash]
      def mesh_element(element)
        { 'name' => element.text, 'major' => element['MajorTopicYN'], 'id' => element['UI'] }
      end

      # The XPath for MESH headings in a MEDLINE database record
      # @return [String, nil]
      def path
        return unless rec.database == 'MEDLINE'
        '/REC/static_data/item/MeshHeadingList/MeshHeading'
      end

  end
end
