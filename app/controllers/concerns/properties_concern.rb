# frozen_string_literal: true

module PropertiesConcern
  extend ActiveSupport::Concern

  # Finds a rent record for a specific month
  def find_rent_for_month(lease, month_str)
    return nil unless valid_month_format?(month_str)
    
    date_range = month_date_range(month_str)
    return nil unless date_range
    
    lease.rents.find do |rent|
      rent_date = rent.payment_date
      rent_date >= date_range[:start_date] && rent_date <= date_range[:end_date]
    end
  end
  
  private
  
  def valid_month_format?(month_str)
    month_str.match?(/\A[A-Z][a-z]{2}-\d{4}\z/)
  end
  
  def month_date_range(month_str)
    month_abbr, year = month_str.split('-')
    month_num = Date::ABBR_MONTHNAMES.index(month_abbr)
    return nil unless month_num
    
    start_date = Date.new(year.to_i, month_num, 1)
    end_date = start_date.end_of_month
    
    { start_date: start_date, end_date: end_date }
  end
end 