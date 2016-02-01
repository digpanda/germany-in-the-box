json.array!(@collections) do |c|
  json.id c.id
  json.name c.name
  json.desc c.desc
  json.visible c.public ? '1' : '0'
  json.products_imgs c.products.map { |p| p.img ? p.img : p.imglg }
end
