class OrderItemSkuIdToEmbeddedSku < Mongoid::Migration
  def self.up
    # we need to convert the sku_id and incorporate it
    # as embedded document
    OrderItem.all.each do |order_item|
      puts "OrderItem Sku ID `#{order_item.sku_id}`"
      if order_item.product.skus.where(id: order_item.sku_id).first
        original_sku = order_item.product.skus.find(order_item.sku_id)
        new_sku = original_sku.clone
        order_item.sku = new_sku
        order_item.sku_origin = original_sku
        # changes which could have been important through the time
        order_item.sku.weight = order_item.weight
        order_item.sku.price = order_item.price
        order_item.sku.option_ids = order_item.option_ids
        order_item.sku.save
        # end of change through the time
        order_item.save
      else
        if order_item.order.nil?
          puts "OrderItem `#{order_item.id}` is an orphan. We will removed it."
          order_item.delete
          puts "Removed successfully."
        else
          puts "Won't be applied to `#{order_item.id}` from order `#{order_item.order.id}` you may need to delete this corrupted order. It will be corrected on further migrations."
        end
      end
    end
  end

  def self.down
  end
end
