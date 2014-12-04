require 'chefspec'

describe 'manage-user::default' do
  
  let(:chef_run) do
    runner = ChefSpec::ChefRunner.new('platform' => 'ubuntu', 'version'=> '12.04')
    runner.converge('manage-user::default')
  end
    
  it 'should include the manage-user recipe by default' do
    expect(chef_run).to include_recipe 'manage-user::default'
  end

end
