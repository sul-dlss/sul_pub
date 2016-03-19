# Show red environment name in pry prompt for non development environments
unless Rails.env.development?
  # Wrap term escapes with '\001' '\002' so readline ignores them in
  # counting the chars on a line; fixes poor line wrapping.
  # term escapes explained at http://misc.flogisoft.com/bash/tip_colors_and_formatting
  # \e[0 is a reset
  # 1; is BOLD
  # 38;5;ColorNumber is foreground color (0..256)
  env = "\001\e[01;38;5;125m\002"
  env += "#{Rails.env.upcase}"
  env += "\001\e[0m\002"  # \e[0m terminates formatting
  old_prompt = Pry.config.prompt
  Pry.config.prompt = [
    proc {|*a| "#{env} #{old_prompt.first.call(*a)}"},
    proc {|*a| "#{env} #{old_prompt.second.call(*a)}"},
  ]
end
