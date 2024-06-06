html = Nokogiri.HTML(content)

categories = html.css('.CategoriesWithShortcutContainer .id-input-container')

if categories.count > 0
    
    # categories.each do |category| # Original
    categories.each_with_index do |category,i| # 3 Iteration Limiter
        next if i >= 3                         # 3 Iteration Limiter

        id = category.at('input')['value']
        cat = category.at_css('.CategoryLabel')&.text.strip 
        pages << {
            url: "https://www.tiendainglesa.com.uy/Categoria/#{cat}/#{id}",
            fetch_type: 'browser',
            page_type: 'listings',
            vars: {
                cat_id: id,
                cat: cat,
                page_number: 1
            }
        }
    end
else
    raise "categories can't be null"
end