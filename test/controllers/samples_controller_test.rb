require 'test_helper'

class SamplesControllerTest < ActionController::TestCase
  test "should get group" do
    get :group
    assert_response :success
  end

  test "should get group_save" do
    get :group_save
    assert_response :success
  end

end
