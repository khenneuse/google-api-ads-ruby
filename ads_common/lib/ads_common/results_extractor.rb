# Encoding: utf-8
#
# Author:: api.dklimkin@gmail.com (Danial Klimkin)
#
# Copyright:: Copyright 2012, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# This class extracts data received from Savon and enriches it.

module AdsCommon
  class ResultsExtractor

    # Instance initializer.
    #
    # Args:
    #  - registry: a registry that defines service
    #
    def initialize(registry)
      @registry = registry
    end

    # Extracts the finest results possible for the given result. Returns the
    # response itself in worst case (contents unknown).
    def extract_result(response, action_name)
      method = @registry.get_method_signature(action_name)
      action = method[:output][:name].to_sym
      result = response.to_hash
      result = result[action] if result.include?(action)
      result = normalize_output(result, method)
      return result[:rval] || result
      return result
    end

    private

    # Extracts misc data from response header.
    def extract_header_data(response)
      header_type = get_full_type_signature(:SoapResponseHeader)
      headers = response.header[:response_header].dup
      process_attributes(headers, false)
      result = headers.inject({}) do |result, (key, v)|
        normalize_output_field(headers, header_type[:fields], key)
        result[key] = headers[key]
        result
      end
      return result
    end

    # Normalizes output starting with root output node.
    def normalize_output(output_data, method_definition)
      fields = method_definition[:output][:fields]
      result = normalize_fields(output_data, fields)
    end

    # Normalizes all fields for the given data based on the fields list
    # provided.
    def normalize_fields(data, fields)
      fields.each do |field|
        field_name = field[:name]
        if data.include?(field_name)
          field_data = data[field_name]
          field_data = normalize_output_field(field_data, field)
          field_data = check_array_collapse(field_data, field)
          data[field_name] = field_data unless field_data.nil?
        end
      end
      return data
    end

    # Normalizes one field of a given data recursively.
    #
    # Args:
    #  - field_data: XML data to normalize
    #  - field_def: field type definition for the data
    #
    def normalize_output_field(field_data, field_def)
      return case field_data
        when Array
          normalize_array_field(field_data, field_def)
        when Hash
          normalize_hash_field(field_data, field_def)
        else
          normalize_item(field_data, field_def)
      end
    end

    # Normalizes every item of an Array.
    def normalize_array_field(data, field_def)
      return data.map {|item| normalize_output_field(item, field_def)}
    end

    # Normalizes every item of a Hash.
    def normalize_hash_field(field, field_def)
      process_attributes(field, true)
      field_type = determine_type(field, field_def[:type])
      type_signature = get_full_type_signature(field_type)
      # If we don't know the type, pass as-is.
      return (type_signature.nil?) ?
          field : normalize_fields(field, type_signature[:fields])
    end

    # Returns field type based on the field structure. Allows to override the
    # type with custom xsi:type.
    def determine_type(field_data, field_type)
      if field_data.kind_of?(Hash) and field_data.include?(:xsi_type)
        field_type = field_data[:xsi_type]
      end
      return field_type
    end

    # Converts one leaf item to a built-in type.
    def normalize_item(item, field_def)
      return case field_def[:type]
        when 'long', 'int' then Integer(item)
        when 'double', 'float' then Float(item)
        when 'boolean' then item.kind_of?(String) ?
            item.casecmp('true') == 0 : item
        else item
      end
    end

    # Checks if the field signature allows an array and forces array structure
    # even for a signle item.
    def check_array_collapse(data, field_def)
      result = data
      if !field_def[:min_occurs].nil? and
          (field_def[:max_occurs] == :unbounded ||
              (!field_def[:max_occurs].nil? and field_def[:max_occurs] > 1))
        result = arrayize(result)
      end
      return result
    end

    # Makes sure object is an array.
    def arrayize(object)
      return [] if object.nil?
      return object.is_a?(Array) ? object : [object]
    end

    # Returns all inherited fields of superclasses for given type.
    def implode_parent(data_type)
      result = []
      if data_type[:base]
        parent_type = @registry.get_type_signature(data_type[:base])
        result += implode_parent(parent_type)
      end
      data_type[:fields].each do |field|
        # If the parent type includes a field with the same name, overwrite it.
        result.reject! {|parent_field| parent_field[:name].eql?(field[:name])}
        result << field
      end
      return result
    end

    # Returns type signature with all inherited fields.
    def get_full_type_signature(type_name)
      result = (type_name.nil?) ? nil : @registry.get_type_signature(type_name)
      result[:fields] = implode_parent(result) if result and result[:base]
      return result
    end

    # Handles attributes received from Savon.
    def process_attributes(data, keep_xsi_type = false)
      if keep_xsi_type
        xsi_type = data.delete(:"@xsi:type")
        data[:xsi_type] = xsi_type if xsi_type
      end
      data.reject! {|key, value| key.to_s.start_with?('@')}
    end
  end
end