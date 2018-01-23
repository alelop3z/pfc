ActionMailer::Base.smtp_settings = {
:address              => "smtp.gmail.com",
:port                 => 587,
:domain               => "veb.alejandrolopeznunez.es",
:user_name            => "USER_NAME",
:password             => "PASSWORD",
:authentication       => "plain",
:enable_starttls_auto => true
}

ActionMailer::Base.default_url_options[:host] = "veb.alejandrolopeznunez.es"