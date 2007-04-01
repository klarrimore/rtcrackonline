ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  #map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  #map.connect ':controller/:action/:id'
  
  map.connect 'webrt/create', :controller => 'webrt', :action => 'create'
  map.connect 'webrt/', :controller => 'webrt', :action => 'list'
  map.connect 'webrt/new', :controller => 'webrt', :action => 'new'
  map.connect '/webrt/', :controller => 'webrt', :action => 'component_update'
  map.connect 'webrt/edit', :controller => 'webrt', :action => 'edit'
  map.connect 'webrt/destroy', :controller => 'webrt', :action => 'destroy'
  map.connect '/webrt/', :controller => 'webrt', :action => 'component'
  map.connect '/webrt/', :controller => 'webrt', :action => 'index'
  map.connect '/webrt/', :controller => 'webrt', :action => 'return_to_main'
  map.connect 'webrt/update', :controller => 'webrt', :action => 'update'
  map.connect 'webrt/cancel', :controller => 'webrt', :action => 'cancel'
  map.connect 'webrt/search', :controller => 'webrt', :action => 'search'
  map.connect 'webrt/find', :controller => 'webrt', :action => 'find'

end
