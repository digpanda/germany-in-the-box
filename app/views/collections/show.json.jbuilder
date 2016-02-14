json.collection {
  json.id @collection.id
  json.name @collection.name
  json.desc @collection.desc
  json.visible @collection.public

  json.set! :products_imgs, @collection.products.map { |p| p.img }.compact

  json.set! :owner_id, @collection.user.id
  json.set! :owner_name, @collection.user.username
  json.set! :owner_img, @collection.user.pic.url ? request.base_url + @collection.user.pic.url : nil
}

json.products @collection.products, partial: 'products/show', as: :product