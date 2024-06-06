html = Nokogiri.HTML(content)

products = html.css('#GridresultsContainerTbl .card-product-container')

var = page['vars']

products.each_with_index do |product, i|
    ### 5 Iteration Limiter
    next if i >= 4

    name = product.at_css(".card-product-body span.card-product-name").text.strip.gsub(" ", "-")
    url = "https://www.tiendainglesa.com.uy/"+CGI.escape(name)+".producto?"+product['data-id']
    rank = i+1
    pages << {
        url: url,
        fetch_type: 'browser',
        page_type: 'products',
        vars: var.merge('rank'=>rank)
    }
end


if var['page_number'] == 1
    total_product = html.css('.wBreadCrumbText')

    if total_product
        total_product = total_product.text.scan(/de (\d+)/).first.first.to_f
        max_page = (total_product/20).ceil
        url_split = page['url'].split('/')[0..-2].join('/')
    
        (2..max_page).each do |page_number|
            url = "#{url_split}/busqueda?0,0,*:*,#{var['cat_id']},0,0,,[],false,[],[],,#{page_number-1}"
            pages << {
                url: url,
                no_url_encode: true,
                fetch_type: 'browser',
                page_type: 'listings',
                vars: {
                    cat_id: var['cat_id'],
                    cat: var['cat'],
                    page_number: page_number
                }
            }
        end 
    end
end
