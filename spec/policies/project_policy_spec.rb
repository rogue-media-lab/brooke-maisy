require "rails_helper"

RSpec.describe ProjectPolicy do
  subject { described_class }

  let(:owner)    { create(:user) }
  let(:stranger) { create(:user) }
  let(:admin)    { create(:user, :admin) }
  let(:project)  { create(:project, user: owner) }

  describe "#show?" do
    it "permits the owner" do
      expect(subject.new(owner, project).show?).to be true
    end

    it "permits an admin" do
      expect(subject.new(admin, project).show?).to be true
    end

    it "denies another client" do
      expect(subject.new(stranger, project).show?).to be false
    end

    it "denies a nil user" do
      expect(subject.new(nil, project).show?).to be false
    end
  end

  describe "Scope" do
    it "returns only the client's own projects" do
      own   = create(:project, user: owner)
      other = create(:project, user: stranger)

      resolved = ProjectPolicy::Scope.new(owner, Project).resolve
      expect(resolved).to include(own)
      expect(resolved).not_to include(other)
    end

    it "returns all projects for an admin" do
      own   = create(:project, user: owner)
      other = create(:project, user: stranger)

      resolved = ProjectPolicy::Scope.new(admin, Project).resolve
      expect(resolved).to include(own, other)
    end
  end
end
