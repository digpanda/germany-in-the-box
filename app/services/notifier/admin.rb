class Notifier
  class Admin < Notifier

    attr_reader :user, :unique_id

    # no specific admin
    # we are using a more classical
    # emailing system
    def initialize
      @user = nil
    end

    def referrer_claimed_money(referrer)
      dispatch(
        email: "info@digpanda.com",
        mailer: AdminMailer,
        title: "Referrer #{referrer.reference_id}",
        desc: "This referrer claimed money. Please check his account and process operations if needed."
      ).perform
    end

    def unvalid_link_detected(link)
      dispatch(
        email: "info@digpanda.com",
        mailer: AdminMailer,
        title: "Link #{link.id}",
        desc: "The end link #{link.raw_url} is not valid, please fix / remove it from the database."
      ).perform
    end

  end
end
