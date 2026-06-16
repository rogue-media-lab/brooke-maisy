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

  describe "POST /admin/clients (invite flow)" do
    it "creates a client and sends a set-password email" do
      sign_in admin

      expect {
        post "/admin/clients", params: { user: { name: "New Person", email: "new@example.com" } }
      }.to change(User, :count).by(1)

      created = User.find_by(email: "new@example.com")
      expect(created.role).to eq("client")
      expect(created.reset_password_sent_at).to be_present
    end
  end
end
