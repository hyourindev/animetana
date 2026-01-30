defmodule AnimetanaWeb.UserSettingsHTML do
  use AnimetanaWeb, :html

  embed_templates "user_settings_html/*"

  def timezone_options do
    [
      {"UTC", "UTC"},
      {"(UTC-12:00) International Date Line West", "Etc/GMT+12"},
      {"(UTC-11:00) Midway Island, Samoa", "Pacific/Midway"},
      {"(UTC-10:00) Hawaii", "Pacific/Honolulu"},
      {"(UTC-09:00) Alaska", "America/Anchorage"},
      {"(UTC-08:00) Pacific Time (US & Canada)", "America/Los_Angeles"},
      {"(UTC-07:00) Mountain Time (US & Canada)", "America/Denver"},
      {"(UTC-06:00) Central Time (US & Canada)", "America/Chicago"},
      {"(UTC-05:00) Eastern Time (US & Canada)", "America/New_York"},
      {"(UTC-04:00) Atlantic Time (Canada)", "America/Halifax"},
      {"(UTC-03:00) Buenos Aires, Georgetown", "America/Argentina/Buenos_Aires"},
      {"(UTC-02:00) Mid-Atlantic", "Atlantic/South_Georgia"},
      {"(UTC-01:00) Azores", "Atlantic/Azores"},
      {"(UTC+00:00) London, Dublin, Lisbon", "Europe/London"},
      {"(UTC+01:00) Berlin, Paris, Rome, Madrid", "Europe/Paris"},
      {"(UTC+02:00) Athens, Istanbul, Cairo", "Europe/Athens"},
      {"(UTC+03:00) Moscow, St. Petersburg", "Europe/Moscow"},
      {"(UTC+04:00) Dubai, Abu Dhabi", "Asia/Dubai"},
      {"(UTC+05:00) Karachi, Islamabad", "Asia/Karachi"},
      {"(UTC+05:30) Mumbai, Chennai, Kolkata", "Asia/Kolkata"},
      {"(UTC+06:00) Dhaka, Almaty", "Asia/Dhaka"},
      {"(UTC+07:00) Bangkok, Hanoi, Jakarta", "Asia/Bangkok"},
      {"(UTC+08:00) Beijing, Hong Kong, Singapore", "Asia/Singapore"},
      {"(UTC+09:00) Tokyo, Seoul", "Asia/Tokyo"},
      {"(UTC+09:30) Adelaide, Darwin", "Australia/Adelaide"},
      {"(UTC+10:00) Sydney, Melbourne", "Australia/Sydney"},
      {"(UTC+11:00) Vladivostok, Solomon Is.", "Asia/Vladivostok"},
      {"(UTC+12:00) Auckland, Wellington", "Pacific/Auckland"},
      {"(UTC+13:00) Nuku'alofa, Samoa", "Pacific/Tongatapu"}
    ]
  end
end
