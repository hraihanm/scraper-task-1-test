

if page['response_status_code'] == 404 

  outputs << {
    _collection: "product_page_404",
  }

  finish
end


html = Nokogiri.HTML(content)
# json = JSON.parse(html.css("script").detect { |i| i.text =~ /dataLayer.push/ }.text.scan(/dataLayer.push\((.*)\)/).first.first)
var = page["vars"]

# json = JSON.parse(html.at_css("script[type='application/ld+json']").text)

# competitor_product_id = html.at_css("#W0265MAINTABLE .TextBlock div") ? html.at_css("#W0265MAINTABLE .TextBlock div")["data-product-id"] : json['productId']
competitor_product_id =html.at_css("#W0265MAINTABLE .TextBlock div")["data-product-id"] rescue nil
competitor_product_id = html.at('form#MAINFORM')['action'].split('?').last if competitor_product_id.nil?
name = html.at_css(".ProductNameFull")&.text.strip
# brand = name.scan(/\b[A-Z]+ \b/).map { |w| w.strip }.join(" ")
# brand = name.split(" ").select { |i| i.upcase.scan(/[A-Z]+/).join("") == i && !(i =~/^\d*\.*\,*\d+$/) }.reject { |j| j.strip.length == 1 || j.split("").uniq.join("") == "A" }.uniq.join(" ")
brand = name.split(" ").select { |i| i.upcase.scan(/[A-ZÉ]+['´-]?[A-ZÉ]+/).join("") == i && !(i =~/^\d*\.*\,*\d+$/) }.reject { |j| j.strip.length == 1 || j.split("").uniq.join("") == "A" }.uniq.join(" ")

# special case DR. BROW´N
brand = "DR. BROW´N" if name.include?('DR. BROW´N')

sub_category_elem = html.at_css(".wBreadCrumbText")&.text.strip.split("/")

sub_arr = []

sub_category_elem.each do |sc|
  unless sc.strip == var["cat"] or sc.strip.downcase == "inicio"
    sub_arr.append("#{sc.strip} ")
  end
end

sub_category = sub_arr.join("> ").strip

is_available = true

customer_price_elem = html.at_css(".wProductPrimaryPrice")

has_discount = false
discount_percentage = nil

if customer_price_elem
  customer_price_lc = html.at_css(".wProductPrimaryPrice").text.gsub(".", "").gsub(",", ".").scan(/\d+[,.]*\d*[,.]*\d*/).first.to_f
  base_price = html.at_css("#TBLPRODUCTDETAILMAIN .wTxtProductPriceBefore")
  base_price = base_price ? base_price.text.gsub(".", "").gsub(",", ".").scan(/\d+[,.]*\d*[,.]*\d*/).first.to_f : customer_price_lc

  if customer_price_lc < base_price
    has_discount = true
    discount_percentage = (((base_price - customer_price_lc) / base_price) * 100).round(7)
  end
else
  is_available = false
  customer_price_lc = nil
  base_price = nil
end

name1 = name.gsub(/INTEX\s+\d+\s+L/,"")

size_regex = [
  /(\d*[\.,]?\d+)\s?(litre)/i,
  /(\d*[\.,]?\d+)\s?(l)/i,
  /(\d*[\.,]?\d+)\s?(ml)/i,
  /(\d*[\.,]?\d+)\s?(cl)/i,
  /(\d*[\.,]?\d+)\s?(cc)/i,
  /(\d*[\.,]?\d+)\s?(cm)/i,
  /(\d*[\.,]?\d+)\s?(g)/i,
  /(\d*[\.,]?\d+)\s?(mg)/i,
  /(\d*[\.,]?\d+)\+?\s?(kg)/i,
  /(\d*[\.,]?\d+)\s?(oz)/i,
  /(\d*[\.,]?\d+)\s?(slice[s]?)/i,
  /(\d*[\.,]?\d+)\s?(sachet[s]?)/i,
  /\d+\s?x\s?(\d*[\.,]?\d+)\s?(s)/i,
  /(\d*[\.,]?\d+)\s?(tablet[s]?)/i,
  /(\d*[\.,]?\d+)\s?(tab[s]?)/i,
  /(\d*[\.,]?\d+)\s?(catridge[s]?)/i,
  /(\d*[\.,]?\d+)\s?(sheet[s]?)/i,
  /(\d*[\.,]?\d+)\s?(stick[s]?)/i,
  /(\d*[\.,]?\d+)\s?(bottle[s]?)/i,
  /(\d*[\.,]?\d+)\s?(caplet[s]?)/i,
  /(\d*[\.,]?\d+)\s?(roll[s]?)/i,
  /(\d*[\.,]?\d+)\s?(tip[s]?)/i,
  /(\d*[\.,]?\d+)\s?(bundle[s]?)/i,
  /(\d*[\.,]?\d+)\s?(pair[s]?)/i,
  /(\d*[\.,]?\d+)\s?(set)/i,
  /(\d*[\.,]?\d+)\s?(kit)/i,
  /(\d*[\.,]?\d+)\s?(pc[s]?)/i,
  /(\d*[\.,]?\d+)\s?(box)/i,
  /(\d*[\.,]?\d+)\s?(per\s?pack)/i,
  /(\d*[\.,]?\d+)\s?(pack)/i,
  /(\d*[\.,]?\d+)\s?(s)(?!\w+)/i,
  /(\d*[\.,]?\d+)\s?([Ss]obres)(?!\w+)/i,
  /(\d*[\.,]?\d+)\s?(m)[^A-Za-z]?/i,
  /(\d*[\.,]?\d+)\s?(page[s]?)[^A-Za-z]?/i,
  /(\d*[\.,]?\d+)\s?(bag)[^A-Za-z]?/i,
  /(\d*[\.,]?\d+)\s?(unidades)/i,
  /(\d*[\.,]?\d+)\s?(w)[^$]/i,
]
size_regex.find { |sr| name1 =~ sr }
std = $1
unit_std = $2
size_std = std.gsub(",", "").to_f rescue nil
size_unit_std = unit_std

if size_std
  if size_std <= 0
    size_std = nil
    size_unit_std = nil
  end
end

name1 = name.gsub(/x\s+\d+$/,"") #For scenario Hub TRUST USB 4 puertos 3.2 Halyx 23327

product_pieces_regex = [
  /(\d+)\s?per\s?pack/i,
  /(\d+)\s?pack/i,
  /(\d+)\s?pcs?/i,
  # /(\d+)\s?x\s?\d+/i,
  # /(?:<!\w+)x\s?(\d+)(?!$)/i,
  /(\d+)\s?hojas/i,
  /(\d+)\s?piezas/i,
].find { |ppr| name1 =~ ppr }
product_pieces = product_pieces_regex ? $1.to_i : 1
product_pieces = 1 if product_pieces == 0
product_pieces ||= 1

description = html.at_css(".ProductDescription")&.text
description = description ? description.strip : nil

img_url = html.at_css("#vVARMAINPRODUCTPICTURE")["src"]

sku = html.at_css(".wProductCodeInfo").text.scan(/\d+/).first.to_s

is_promoted = false
type_of_promotion = nil

# promo = html.at_css(".wPromoTextInProduct").text rescue []
promo = html.at_css(".wPromoTextInProductDisplay").text rescue []

promo_arr = []

unless promo.empty?
  promo_arr.append("'#{promo}'")
end

if promo_arr.length > 0
  is_promoted = true
  type_of_promotion = "badges"
  promo_values = promo_arr.join(", ")
end

promo_attributes = promo.empty? ? nil : JSON.generate({
  "promo_detail" => promo_values,
})

brandCompArr = ['tienda', 'inglesa', 'inglea']
is_private_label = brand.empty? ? nil : !brandCompArr.any?{|l| (brand.downcase.include?(l))}
is_private_label = nil if brand.nil? || brand.empty?

barcode = html.at_css('#TXTPRODUCTBARCODE').text.strip.scan(/\d+/).first.strip

# item_identifiers = JSON.generate({
#   "barcode" => "'#{barcode}'",
# })
item_identifiers = nil

# item_attributes_elem = html.css("#W0062GRID1TABLE_0001 img")
item_attributes_elem = html.css('#W0058Grid1ContainerTbl img')
item_arr = []


item_attributes_elem.each do |item_att|
  item_arr.append("'#{item_att["title"]}'")
end

if item_arr.length > 0
  item_attributes_values = item_arr.join(", ")
  item_attributes = JSON.generate({
    "item badge" => item_attributes_values,
  })
end

product = {
  _id: competitor_product_id,
  _collection: "products",
  competitor_name: "TIENDA INGLESA",
  competitor_type: "dmart",
  store_name: nil,
  store_id: nil,
  country_iso: "UY",
  language: "SPA",
  currency_code_lc: "UYU",
  scraped_at_timestamp: ((ENV['needs_reparse'] == 1 || ENV['needs_reparse'] == "1") ? (Time.parse(page['fetched_at']) + 1).strftime('%Y-%m-%d %H:%M:%S') : Time.parse(page['fetched_at']).strftime('%Y-%m-%d %H:%M:%S')),
  competitor_product_id: competitor_product_id,
  name: name,
  brand: brand,
  category_id: var["cat_id"],
  category: var["cat"],
  sub_category: sub_category,
  customer_price_lc: customer_price_lc,
  base_price_lc: base_price,
  has_discount: has_discount,
  discount_percentage: discount_percentage,
  rank_in_listing: var["rank"],
  page_number: var["page_number"],
  product_pieces: product_pieces,
  size_std: size_std,
  size_unit_std: size_unit_std,
  description: description,
  img_url: img_url,
  barcode: barcode,
  sku: sku,
  url: page["url"],
  is_available: is_available,
  crawled_source: "WEB",
  is_promoted: is_promoted,
  type_of_promotion: type_of_promotion,
  promo_attributes: promo_attributes,
  is_private_label: is_private_label,
  latitude: nil,
  longitude: nil,
  reviews: nil,
  store_reviews: nil,
  item_attributes: item_attributes,
  item_identifiers: item_identifiers,
  country_of_origin: nil,
  variants: nil,
}

outputs << product
