require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'pry'
require 'date'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists? 'output'

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(number)
  if number.size == 11 && number[0] == 1
    number[1..10]
  else
    number.to_s.rjust(10, '0')[0..9]
  end
end

def find_peak_times(contents)
  hours = Hash.new(0)
  contents.each do |line|
    time = DateTime.strptime(line[:regdate], '%m/%d/%y %H:%M')
    hour = time.hour
    hours[hour] += 1
  end
  hours.sort_by { |k, v| -v}
end

contents = CSV.open '../event_attendees.csv', headers: true, header_converters: :symbol

find_peak_times(contents)

template_letter = File.read '../form_letter.erb'
erb_template = ERB.new template_letter

contents.each do |line|
  id = line[0]
  name = line[:first_name]

  zipcode = clean_zipcode(line[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
