# encoding: UTF-8
require 'yaml'

def find_ancestor(gen, name)
  ancestor = nil
  gen.each do |pairnode|
    if not pairnode['children'].nil?
      pairnode['children'].each_with_index do |child, i|
        if child['name'] == name
          if not ancestor.nil?
            raise "Conflict #{name}"
          end
          ancestor = {pairnode: pairnode, child_index: i}
        end
      end
    end
  end
  ancestor
end

def render_tree(pairnode)
  if not pairnode.nil?
    puts "<div>"
    if pairnode.has_key?('father')
      puts "<div><span class=label>บิดา:</span><span>#{pairnode['father']['name']}</span></div>"
    else
      "<div><span class=label>บิดา:</span><span>ไม่ทราบชื่อ</span></div>"
    end
    if pairnode.has_key?('mother')
      puts "<div><span class=label>มารดา:</span><span>#{pairnode['mother']['name']}</span></div>"
    else
      puts "<div><span class=label>มารดา:</span><span>ไม่ทราบชื่อ</span></div>"
    end
    
    if pairnode.has_key?('children')
      puts "<span class=label>บุตร:</span>"
      puts "<div class=children>"
      puts "<ol>"
      pairnode['children'].each do |child|
        puts "<li>"
        puts "#{child['name']}"
        if child.has_key?('links')
          child['links'].each do |link|
            render_tree(link)
          end
        end
        puts "</li>"
        
      end
      puts "</ol>"
      puts "</div>"
    end
    
    puts "</div>"
  end
end

if ARGV.length != 1
  $stderr.puts "Usage: ruby #{$0} <family data>.yaml"
  exit 1
end

raw_data = File.open(ARGV[0], 'r:UTF-8').read
data = YAML.load(raw_data)

gens = []

data['pairnodes'].each do |pairnode|
  if gens[pairnode['gen']].nil?
    gens[pairnode['gen']] = []
  end
  gens[pairnode['gen']] << pairnode
end

root = gens[1][0]
for g in 2..(gens.length - 1)
  gens[g].each do |pairnode|
    ancestor = nil
    if not pairnode['father'].nil?    
      ancestor = find_ancestor(gens[g-1], pairnode['father']['name'])
    end
    if not pairnode['mother'].nil? and ancestor.nil?
      ancestor = find_ancestor(gens[g-1], pairnode['mother']['name'])
    end
    if ancestor.nil?
      raise "Ancestor not found GEN=#{g} #{pairnode.inspect} "
    end
    ancestor_pairnode = ancestor[:pairnode]
    child_index = ancestor[:child_index]
    if not ancestor_pairnode['children'][child_index].has_key?('links')
      ancestor_pairnode['children'][child_index]['links'] = []
    end
    ancestor_pairnode['children'][child_index]['links'] << pairnode
  end
end

puts "<!doctype html>"
puts "<html>"
puts "<head>"
puts "<meta charset=\"UTF-8\">"
puts "<link rel=\"stylesheet\" href=\"style.css\" type=\"text/css\" charset=\"utf-8\">"
puts "</head>"
puts "<div class=main>"
puts "<h1>สาแหรกครอบครัวสัตยมาศ/สัจจมาศ/สัจมาศ/สัตย์มาตย์</h1>"
render_tree(root)
puts "<div class=note>#{data['note']}</div>"
puts "</div>"
puts "</html>"
