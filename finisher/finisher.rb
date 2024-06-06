i = 1
products = []
begin
  outputs = find_outputs("list_products", {}, i, 500)

  outputs.each do |output|
    unless products.include?(output["competitor_product_id"])
      products.append(output["competitor_product_id"])
    end
  end

  i += 1
end while outputs.length > 0


products.each do |product|
  un_outputs = find_outputs("list_products", {"competitor_product_id": product}, 1, 500)

  filtered_output = un_outputs[0]
  filtered_output["_collection"] = "products"

  outputs << filtered_output
  save_outputs outputs if outputs.length > 99
end

save_outputs outputs
