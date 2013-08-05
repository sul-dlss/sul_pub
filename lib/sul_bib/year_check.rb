module SulBib
  class YearCheck < Grape::Validations::Validator
  def validate_param!(attr_name, params)
    unless (1000..2100).include?(params[attr_name])
      throw :error, :status => 400, :message => "#{attr_name} must be four digits long and fall between 1000 and 2100"
    end
  end
end

end