describe 'Documentation routing' do
  it 'routes root path to api' do
    expect(get: '/').to route_to(
      id: 'home',
      controller: 'high_voltage/pages',
      action: 'show'
    )
  end
  it 'routes /home to home' do
    expect(get: '/home').to route_to(
      id: 'home',
      controller: 'high_voltage/pages',
      action: 'show'
    )
  end
  it 'routes /pubapi to pubapi' do
    expect(get: '/pubapi').to route_to(
      id: 'pubapi',
      controller: 'high_voltage/pages',
      action: 'show'
    )
  end
  it 'routes /pubsapi to pubsapi' do
    expect(get: '/pubsapi').to route_to(
      id: 'pubsapi',
      controller: 'high_voltage/pages',
      action: 'show'
    )
  end
  it 'routes /pollapi to pollapi' do
    expect(get: '/pollapi').to route_to(
      id: 'pollapi',
      controller: 'high_voltage/pages',
      action: 'show'
    )
  end
  it 'routes /authorshipapi to authorshipapi' do
    expect(get: '/authorshipapi').to route_to(
      id: 'authorshipapi',
      controller: 'high_voltage/pages',
      action: 'show'
    )
  end
  it 'routes /queryapi to queryapi' do
    expect(get: '/queryapi').to route_to(
      id: 'queryapi',
      controller: 'high_voltage/pages',
      action: 'show'
    )
  end
end
