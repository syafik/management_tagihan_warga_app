class Time
  def self.greeting_message_time
    s_hours = Time.current.hour
    if s_hours >= 0 || s_hours < 12
      "Selamat Pagi"
    elsif s_hours >= 12 && s_hours < 15
      "Selamat Siang"
    elsif s_hours >= 15 && s_hours < 18
      "Selamat Sore"
    elsif s_hours >= 18 && s_hours < 24
      "Selamat Malam"
    end

  end
end