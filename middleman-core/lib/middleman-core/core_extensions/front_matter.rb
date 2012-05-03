# Parsing YAML frontmatter
require "yaml"

# Frontmatter namespace
module Middleman::CoreExtensions::FrontMatter
  
  # Setup extension
  class << self
    
    # Once registered
    def registered(app)
      ::Middleman::Sitemap::Resource.send :include, ResourceInstanceMethods
      
      app.send :include, InstanceMethods
            
      # Setup ignore callback
      app.after_configuration do
        sitemap.provides_metadata do |path|
          fmdata = frontmatter_and_content(path).first

          data = {}
          %w(layout layout_engine).each do |opt|
            data[opt.to_sym] = fmdata[opt] if fmdata[opt]
          end
          
          { :options => data, :page => fmdata }
        end
        
        ignore do |path|
          if p = sitemap.find_resource_by_path(path)
            !p.proxy? && p.data && p.data["ignored"] == true
          else
            false
          end
        end
      end
    end
    alias :included :registered
    
    # Parse frontmatter out of a string
    # @param [String] content
    # @return [Array<Hash, String>]
    def parse_front_matter(content)
      yaml_regex = /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
      if content =~ yaml_regex
        content = content[($1.size + $2.size)..-1]

        begin
          data = YAML.load($1)
        rescue => e
          puts "YAML Exception: #{e.message}"
          return false
        end

      else
        return false
      end

      [data, content]
    rescue
      [{}, content]
    end
  end
  
  module ResourceInstanceMethods

    # This page's frontmatter
    # @return [Hash]
    def data
      app.frontmatter_and_content(source_file).first
    end
    
  end
  
  module InstanceMethods
    
    # Get the frontmatter and plain content from a file
    # @param [String] path
    # @return [Array<Thor::CoreExt::HashWithIndifferentAccess, String>]
    def frontmatter_and_content(path)
      full_path = File.expand_path(path, source_dir)
      content = File.read(full_path)

      result = ::Middleman::CoreExtensions::FrontMatter.parse_front_matter(content)

      if result
        data, content = result
        data = ::Middleman::Util.recursively_enhance(data).freeze
      else
        data = {}
      end

      [data, content]
    end
    
    
    # Get the template data from a path
    # @param [String] path
    # @return [String]
    def template_data_for_file(path)
      frontmatter_and_content(path).last
    end
    
  end
    
end
