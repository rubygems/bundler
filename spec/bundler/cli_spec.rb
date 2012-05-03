require 'spec_helper'


describe 'bundle executable' do
  it 'returns non-zero exit status when passed unrecognized options' do
    bundle '--invalid_argument', :exitstatus => true
    exitstatus.should_not == 0
  end
end

