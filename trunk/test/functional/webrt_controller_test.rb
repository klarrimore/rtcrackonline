require File.dirname(__FILE__) + '/../test_helper'
require '/webrt_controller'

# Re-raise errors caught by the controller.
class WebrtController; def rescue_action(e) raise e end; end

class WebrtControllerTest < Test::Unit::TestCase
  fixtures :webrts

  def setup
    @controller = WebrtController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # A better generator might actually keep updated tests in here, until then its probably better to have nothing than something broken

end
