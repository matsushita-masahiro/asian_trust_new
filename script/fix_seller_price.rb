# script/fix_seller_price.rb
items = PurchaseItem.where(seller_price: 0)
puts "targets: #{items.count}"

items.find_each do |it|
  level_id = Purchase.where(id: it.purchase_id).pick(:user_id)
                     .then { |uid| User.where(id: uid).pick(:level_id) }
  next unless level_id

  prc = ProductPrice.where(product_id: it.product_id, level_id: level_id).pick(:price)
  next unless prc

  it.update!(seller_price: prc)
  puts "fixed item##{it.id}: seller_price=#{prc}"
end
