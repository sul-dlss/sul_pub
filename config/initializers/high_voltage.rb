HighVoltage.configure do |config|
  config.routes = false
end

HighVoltage.route_drawer = HighVoltage::RouteDrawers::Root