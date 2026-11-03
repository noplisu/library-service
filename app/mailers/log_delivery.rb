class LogDelivery
  def initialize(_settings)
  end

  def deliver!(mail)
    Rails.logger.info(
      "Reminder email to=#{Array(mail.to).join(", ")} subject=#{mail.subject.inspect} body=#{mail.body.decoded.inspect}"
    )
  end
end
