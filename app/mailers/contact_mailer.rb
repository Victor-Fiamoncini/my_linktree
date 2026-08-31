class ContactMailer < ApplicationMailer
  def new_contact(name:, email:, message:)
    @name = name
    @email = email
    @message = message

    mail(to: Rails.application.credentials.dig(:mailer, :recipient_email), subject: "My Linktree - New contact from #{name}")
  end

  def agent_hire_request(name:, contact:, brief:, agent: nil)
    @name = name
    @contact = contact
    @brief = brief
    @agent = agent

    mail(to: Rails.application.credentials.dig(:mailer, :recipient_email), subject: "My Linktree - Agent contact from #{name}")
  end
end
