require 'spec_helper'

describe 'pow' do
  let(:facts) do
    {
      :boxen_home => '/opt/boxen'
    }
  end

  it do
    should contain_class('pow')
    should contain_package('pow')
  end
end
