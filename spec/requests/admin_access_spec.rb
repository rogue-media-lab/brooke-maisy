require "rails_helper"

RSpec.describe "Admin access control", type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:client) { create(:user) }

  describe "GET /admin" do
    it "redirects an unauthenticated visitor to sign in" do
      get "/admin"
      expect(response).to redirect_to("/users/sign_in")
    end

    it "blocks a signed-in client" do
      sign_in client
      get "/admin"
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/admin/i)
    end

    it "allows an admin" do
      sign_in admin
      get "/admin"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/clients" do
    it "creates a client record" do
      sign_in admin

      expect {
        post "/admin/clients", params: { client: { name: "New Person", email: "new@example.com", phone: "555-1234" } }
      }.to change(Client, :count).by(1)

      created = Client.find_by(email: "new@example.com")
      expect(created.name).to eq("New Person")
    end
  end
end
