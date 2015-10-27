module SulBib
  class YearCheck < Grape::Validations::Base
    def validate_param!(attr_name, params)
      throw :error, status: 400, message: "#{attr_name} must be four digits long and fall between 1000 and 2100" unless (1000..2100).include?(params[attr_name])
    end
  end
end
