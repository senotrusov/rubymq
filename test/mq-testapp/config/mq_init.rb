
RubyMQ.initialize_orm :activerecord

RubyMQ.load_path(RubyMQ.root / "app" / "models")
RubyMQ.load_path(RubyMQ.root / "app" / "mq")

RubyMQ.application(:name => :periodic) do |app|
  app.endpoint(:name => :simple_endpoint, :application => TestEndpointApplication) do |endpoint|
    endpoint.schedule "periodic", :active => true, :active_since => Time.now, :active_till => Time.now + 1.minute, :interval => 20
    endpoint.producer "/test/print"
  end
end

RubyMQ.application(:name => :print_app) do |app|
  app.endpoint(:name => :simple_endpoint, :application => TestEndpointApplication) do |endpoint|
    endpoint.consumer "/test/print", :name => :print
    endpoint.producer "/test/print-out"
  end
end

RubyMQ.application(:name => :post_print_app) do |app|
  app.endpoint(:name => :simple_endpoint, :application => TestEndpointApplication) do |endpoint|
    endpoint.consumer "/test/print-out", :name => :post_print
  end
end

