require 'fileutils'

# any manipulation linked to the orders which goes to BorderGuru FTP is handable from here
module BorderGuruFtp
  class TransferOrders

    attr_reader :orders

    def initialize(orders)
      @orders = orders
    end

    # generate the CSVs from the orders and store it locally
    def generate_and_store_local
      orders_by_shop.each do |shop_orders|
        if has_order_items?(shop_orders)
          Makers::Store.new(shop_orders, generate_csv(shop_orders)).to_local
        end
      end
    end

    # etablish a connection and push the files into the server
    def connect_and_push_remote
      connection.establish!
      push_to_server
      connection.leave! if connection
    end

    # it refreshes each order status
    # NOTE : it's kind of a replica of generate_and_store_local and could be better managed
    # in the current system we don't check if the order was actually sent
    def refresh_orders_status
      orders_by_shop.each do |shop_orders|
        if has_order_items?(shop_orders)
          shop_orders.each do |shop_order|
            shop_order.status = :custom_checking
            shop_order.save
          end
        end
      end
    end

    # clean up the local folder after manipulations
    def clean_local_storage
      FileUtils.rm_rf(BorderGuruFtp.local_directory)
    end

    private

    def connection
      @connection ||= Senders::Connect.new
    end

    def push_to_server
      csv_files.each do |file_path|
        Senders::Push.new(connection.current, file_path).to_remote
      end
    end

    def csv_files
      Senders::Prepare.new.fetch
    end

    def generate_csv(orders)
      Makers::Generate.new(orders).to_csv
    end

    def has_order_items?(orders) # could be refactored into a model ?
      orders.each do |order|
        return true if order.order_items.any?
      end
      false
    end

    def orders_by_shop
      @orders_by_shop ||= orders.group_by(&:shop_id).values
    end

  end
end
