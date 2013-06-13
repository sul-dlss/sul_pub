class CapAuthorshipMailer < ActionMailer::Base
  default from: "from@example.com"

  def welcome_email(message)
  #  @user = user
  #  @url  = "http://example.com/login"
    mail(:to => "***REMOVED***@gmail.com", :subject => message)
  end

end
