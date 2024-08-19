# frozen_string_literal: true

module WebOfScience
  # Map WOS record abstract data into the SUL PubHash data
  class MapMesh < Mapper
    # MESH details
    # @return [Hash]
    def pub_hash
      mesh.empty? ? {} : { mesh_headings: mesh }
    end

    private

    attr_reader :mesh

    # Extract content from record, try not to hang onto the entire record
    # @param rec [WebOfScience::Record]
    def extract(rec)
      super
      @mesh = extract_mesh(rec)
    end

    def extract_mesh(rec)
      return {} unless database == 'MEDLINE'

      headings = mesh_headings(rec)
      headings.map do |mesh_heading|
        h = {
          'descriptor' => mesh_descriptors(mesh_heading),
          'qualifier' => mesh_qualifiers(mesh_heading),
          'treecode' => mesh_treecodes(mesh_heading)
        }
        h.deep_symbolize_keys
      end
    end

    # Extract content from the XPath for MESH headings in a MEDLINE database record
    # @return [Nokogiri::XML::NodeSet]
    def mesh_headings(rec)
      rec.doc.xpath('/REC/static_data/item/MeshHeadingList/MeshHeading')
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
  end
end
