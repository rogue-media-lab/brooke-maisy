require "rails_helper"

RSpec.describe Project do
  it "is valid with a user and title" do
    expect(build(:project)).to be_valid
  end

  it "requires a title" do
    project = build(:project, title: nil)
    expect(project).not_to be_valid
  end

  it "defaults status to discovery" do
    project = Project.new(user: create(:user), title: "Untitled")
    expect(project.status).to eq("discovery")
  end

  it "destroys dependent updates" do
    project = create(:project)
    create(:project_update, project: project)
    expect { project.destroy }.to change(ProjectUpdate, :count).by(-1)
  end

  describe "ProjectUpdate scopes" do
    it "client_visible returns only visible updates" do
      project = create(:project)
      visible = create(:project_update, project: project, visible_to_client: true)
      create(:project_update, project: project, visible_to_client: false)

      expect(project.project_updates.client_visible).to eq([ visible ])
    end
  end
end
