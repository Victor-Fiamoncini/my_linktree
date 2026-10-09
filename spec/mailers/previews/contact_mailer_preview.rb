# Preview at /rails/mailers/contact_mailer
class ContactMailerPreview < ActionMailer::Preview
  def new_contact
    ContactMailer.new_contact(name: "Jane Doe", email: "jane@example.com", message: "Hi Victor!\n\nI'd love to chat about a Rails project.")
  end

  def agent_hire_request
    ContactMailer.agent_hire_request(name: "Jane Doe", contact: "jane@example.com", brief: "Build a Rails 8 API with an MCP server.", agent: "Claude")
  end
end
