require 'open-uri'
require 'rubygems'
require 'zip'

class BillsHandler < BaseService
  attr_reader :orders, :threads

  include Rails.application.routes.url_helpers

  TEMPORARY_DIRECTORY = "#{Rails.root}/tmp/official_bills/".freeze
  DESTINATION_DIRECTORY = "#{Rails.root}/public/uploads/zip/".freeze

  def initialize(orders)
    @orders = orders
    @threads = []
  end

  def zip
    ensure_temporary_directory

    # we fill-in the temporary directory
    orders.each do |order|
      # we need to open a new thread in case the request is locked
      # this happens in development often
      threads << Thread.new do
        download_official_bill(order)
      end
    end

    # we wait until all threads are finished
    # with their own process
    threads.each { |thread| thread.join }

    # now we zip it
    zip_directory

    # we remove the temporary files
    remove_temporary_directory

    end_path
  end

  private

  def end_path
    '/uploads/zip/official-billing.zip'
  end

  def zip_directory
     ZipFileGenerator.new(TEMPORARY_DIRECTORY, "#{DESTINATION_DIRECTORY}official-billing.zip").write
  end

  def download_official_bill(order)
    order_url = shared_order_rendered_official_bill_url(order, format: :pdf, disposition: :inline)
    # NOTE : this makes huge problems in local.
    # Find a work around if the problem persists on production.
    download = open(order_url)
    filename = download.base_uri.to_s.split('/')[-1]
    IO.copy_stream(download, "#{TEMPORARY_DIRECTORY}#{filename}")
  end

  def ensure_temporary_directory
    FileUtils.mkdir_p(TEMPORARY_DIRECTORY)
  end

  def remove_temporary_directory
    FileUtils.rm_rf(TEMPORARY_DIRECTORY)
  end

end
