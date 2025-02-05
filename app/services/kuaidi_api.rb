class KuaidiApi < BaseService
  attr_reader :delivery_id, :delivery_provider

  def initialize(delivery_id: nil, delivery_provider: nil)
    @delivery_id = delivery_id
    @delivery_provider = delivery_provider
  end

  def perform!
    if [:not_found, :error, :wrong_status].include? current_status.keys.first
      return_with(:error, current_status[current_status.keys.first])
    else
      return_with(:success, current_status: current_status,
                            current_state: current_state,
                            current_history: current_history)
    end
  end

  # 0：query not found
  # 1：query success，
  # 2：query error
  def current_status
    case raw_status
    when 0
      { not_found: raw_message }
    when 1
      { success: raw_message }
    when 2
      { error: raw_message }
    else
      { wrong_status: 'Unknown response status' }
    end
  end

  # 0：shippmemnt on the way
  # 1：accepted, the package is received by logistics partner
  # 2：problem，the package got a problem during delivery
  # 3：received signiture，the recipient signed and took the package
  # 4: returned signiture，the recipient signed to return the package
  # 5：local distribution, the package is in the target city distribution center；
  # 6：returned， the package is on the way back to germany
  def current_state
    case raw_state
    when 0
      :processing
    when 1
      :accepted
    when 2
      :problem
    when 3
      :signature_received
    when 4
      :signature_returned
    when 5
      :local_distribution
    when 6
      :returned
    else
      :wrong_state
    end
  end

  def current_history
    gateway['data']
  end

  def public_url(callback_url: nil)
    if delivery_id
      "https://m.kuaidi100.com/index_all.html?type=#{delivery_provider}&postid=#{delivery_id}&callbackurl=#{callback_url}"
    end
  end

  private

    def raw_message
      gateway['message']
    end

    def raw_status
      gateway['status'].to_i
    end

    def raw_state
      gateway['state'].to_i
    end

    def gateway
      @gateway ||= Parser.get_json end_url
    end

    def end_url
      "http://api.kuaidi100.com/api?id=#{access_id}&com=#{delivery_provider}&nu=#{delivery_id}"
    end

    # given key for digpanda
    def access_id
      ENV['kuaidi_api_key']
    end
end
