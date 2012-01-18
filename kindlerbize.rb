
# take toc.ncx

require 'nokogiri'
require 'fileutils'
require 'yaml'
require 'date'

# Get html pages in document order

html_pages = Nokogiri::XML(File.read("toc.ncx")).search("navMap//content[@src]").map {|c| c[:src]}.uniq

frontmatter = []

html_pages.delete_if {|x| 
  # we need to treat frontmatter differently
  if x =~ /(toc|welcome|credits|copyright).html/
    frontmatter << x unless x =~ /toc/
    true
  end

}

puts "=> Making one section for all frontmatter."
html = frontmatter.map {|x|
  Nokogiri::HTML(File.open(x)).at("body").inner_html
}.join("\n")

fdoc = Nokogiri::HTML(html)

# need to turn author h3's into h4's
fdoc.search("h3").each { |h3|
  if h3[:class] != 'section'
    h3.name = 'h4'
  else # add an id
    h3['id'] = h3.inner_text.gsub(/\s/, '-')
  end
}
fdoc.search("h2").each { |h2| 
  h2.name = 'h3'
  h2['id'] = h2.inner_text.gsub(/\s/, '-')
}

head = Nokogiri::XML::Node.new "head", fdoc
title_node = Nokogiri::XML::Node.new "title", fdoc
title_node.content = "Frontmatter"
title_node.parent = head
fdoc.at("body").before head
File.open("frontmatter.html",'w'){|f| f.puts fdoc.to_html}

html_pages.unshift "frontmatter.html"

puts "=> Making one section folder per original HTML file"

html_pages.each_with_index { |page, section_idx|
  FileUtils::mkdir_p("sections/%03d" % section_idx)
  doc = Nokogiri::HTML(File.open(page))
  title = doc.at("title").inner_text.gsub("Ruby on Rails Guides: ", '')
  title = page.capitalize.gsub('.html', '') if title.strip == ''
  File.open("sections/%03d/_section.txt" % section_idx, 'w') {|f| f.puts title}
  puts "sections/%03d -> #{title}" % section_idx
  
  # Fragment the page file into subsections
  doc.xpath("//h3[@id]").each_with_index { |h3,item_idx|
    subsection = h3.inner_text
    content = h3.xpath("./following-sibling::*").take_while {|x| x.name != "h3"}.map {|x| x.to_html}
    item = Nokogiri::HTML(h3.to_html + content.join("\n"))
    item_path = "sections/%03d/%03d.html" % [section_idx, item_idx] 

    # add head node and title node
    head = Nokogiri::XML::Node.new "head", item
    title_node = Nokogiri::XML::Node.new "title", item
    title_node.content = subsection
    title_node.parent = head
    item.at("body").before head

    # fix all image links
    item.search("img").each { |img|
      img['src'] = "#{Dir.pwd}/#{img['src']}"
    }


    File.open(item_path, 'w'){|f| f.puts item.to_html}
    puts "  #{item_path} -> #{subsection}"

  }
}

puts "=> Generating _document.yml"


x = Nokogiri::XML(File.open("rails_guides.opf")).remove_namespaces!

document = {
  'doc_uuid' => x.at("package")['unique-identifier'],
  'title' => x.at("title").inner_text,
  'publisher' => x.at("publisher").inner_text,
  'author' => x.at("creator").inner_text,
  'subject' => x.at("subject").inner_text,
  'date' => x.at("date").inner_text,
  'cover' => x.at("item[@id=cover]")[:href],
  'masthead' => x.at("item[@id=cover]")[:href],
  'mobi_outfile' => "rails-guide.#{Date.today.to_s}.mobi"
}
puts document.inspect
File.open("_document.yml", 'w'){|f| f.puts document.to_yaml}

exec "kindlerb ."

