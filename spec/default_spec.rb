require 'chefspec'

describe 'manage-users::default' do
  
  let(:chef_run) do
    runner = ChefSpec::ChefRunner.new('platform' => 'ubuntu', 'version'=> '12.04')
    runner.converge('manage-users::default')
  end
    
  it 'should include the manage-users recipe by default' do
    expect(chef_run).to include_recipe 'manage-users::default'
  end

end
