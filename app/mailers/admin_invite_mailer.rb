class AdminInviteMailer < ApplicationMailer
  def invitation_email(admin, invited_by_name)
    @admin = admin
    @invited_by_name = invited_by_name
    @frontend_url = ENV.fetch("FRONTEND_URL", "https://app.shimizu-technology.com")

    mail(
      to: admin.email,
      subject: "You've been invited to the Golf Tournament Admin Portal"
    )
  end
end
