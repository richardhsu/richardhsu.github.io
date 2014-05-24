module Jekyll
  # Simplified revision of  http://davidensinger.com/ category and tag generator
  class TagsGenerator < Generator

    safe true

    def generate(site)
      # Go through each tag
      site.tags.each do |tag|
        tag[1] = tag[1].sort_by { |post| -post.date.to_f }
        # Calculate pages and generate
        pages = Pager.calculate_pages(tag[1], site.config["paginate"].to_i)
        (1..pages).each do |num_page|
          pager = Pager.new(site, num_page, tag[1], pages)
          path = "/tag/#{tag[0]}".downcase.strip.gsub(' ', '-')
          if num_page > 1
            path = path + "/page#{num_page}"
          end
          newpage = TagSubPage.new(site, site.source, path, tag[0])
          newpage.pager = pager
          site.pages << newpage
        end
      end
    end
  end

  class TagSubPage < Page
    def initialize(site, base, dir, val)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), "tag_index.html")
      self.data['tag'] = val
    end
  end

end
