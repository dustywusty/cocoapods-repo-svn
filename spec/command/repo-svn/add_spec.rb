require File.expand_path('../../../spec_helper', __FILE__)

# https://github.com/clarkda/CocoaPods/blob/master/spec/functional/command/repo/add_spec.rb

module Pod
  describe Command::RepoSvn::Add do
    extend SpecHelper::TemporaryRepos

    before do
      set_up_test_repo
    end

    it 'returns the proper command class' do
      Command.parse(%w( repo-svn add )).should.be.instance_of Command::RepoSvn::Add
    end

    it 'fails without a repository url or name' do
      command = Command.parse(%w( repo-svn add ))
      lambda { command.validate! }.should.raise CLAide::InformativeError
    end

    it 'adds a svn spec repo' do

    end
  end
end
