require "rails_helper"

RSpec.describe Project do
  it "is valid with a client and title" do
    project = Project.new(client: create(:client), user_id: create(:user).id, title: "Test Project")
    expect(project).to be_valid
  end

  it "requires a title" do
    project = Project.new(client: create(:client), user_id: create(:user).id, title: nil)
    expect(project).not_to be_valid
  end

  it "defaults status to discovery" do
    project = Project.new(client: create(:client), user_id: create(:user).id, title: "Untitled")
    expect(project.status).to eq("discovery")
  end

  it "destroys dependent updates" do
    skip "pending migration: purchase_orders now references quote_id, not project_id"
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
