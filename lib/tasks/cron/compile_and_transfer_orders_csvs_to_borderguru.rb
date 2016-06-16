class CompileAndTransferOrdersCsvsToBorderguru

  def initialize

    #
    # We check the correct orders via a good old loop system (Viva Mongoid !)
    #
    orders = []
    User.where(role: :shopkeeper).each do |user|
      user.orders.where(status: :custom_checking).each do |order|
        orders << order
      end
    end

    # We start by processing into a CSV file
    #
    csv_file_path = TurnOrdersIntoCsvAndStoreIt.new(orders)

    if csv_file_path == false
      devlog "A problem occured while preparing the orders."
    end

    #
    # We transfer the information to BorderGuru
    # We could avoid opening the file twice but it's a double process.
    #
    files_pushed = PushCsvsToBorderguruFtp.new

    if files_pushed == false
      devlog "A problem occured while transfering the files to BorderGuru."
    end

  end

  def devlog(content)
    @@devlog ||= Logger.new("#{::Rails.root}/log/borderguru_cron.log")
    @@devlog.info content
    puts content
  end

end