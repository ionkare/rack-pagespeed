require 'jsmin'
begin
  require 'md5'
rescue LoadError
  require 'digest/md5'
end

class Rack::PageSpeed::Filters::MinifyJavaScript < Rack::PageSpeed::Filters::Base
  name 'minify_javascript'
  requires_store
      
  def execute! document
    nodes = document.css('script')
    return false unless nodes.count > 0
    nodes.each do |node|
      if !node['src']
        node.content = JSMin.minify node.content
      else
        if match = %r(^/rack-pagespeed-(.*)).match(node['src'])
          store = @options[:store]
          store[match[1]] = JSMin.minify store[match[1]]
        else
          next unless local_script? node
          file = file_for node
          javascript = file.read
          hash = Digest::MD5.hexdigest file.mtime.to_i.to_s + javascript
          compressed = Nokogiri::XML::Node.new 'script', document
          compressed['src'] = "/rack-pagespeed-#{hash}.js"
          @options[:store]["#{hash}.js"] = JSMin.minify javascript
          node.before compressed
          node.remove
        end        
      end
    end
  end
  
  def local_script? node
    node['src'] and !(node['src'] =~ /^http/ or !(node['src'] =~ /.js$/))
  end
end