class CurrencyDataConversion < Mongoid::Migration
  
  def self.up
      # EDITED C/C FROM RAKE TASK `bugfix`
    Shop.all.each do |s|
      if s.currency.nil?
        puts "Fixing shop #{s.name} ; converting `nil` currency to `EUR`"
        s.currency = 'EUR'
        s.save(validate: false)
      else
        puts "Nothing to do to shop #{s.name}"
      end
    end
  end

  def self.down
  end

end