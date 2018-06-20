require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'
require 'pry'


puts 'EventManager initialized.'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_number(phone, *args)
  args.each do |arg|
    phone = phone.split(arg).join
  end
  phone
end

def clean_phone(phone)
  phone = clean_number(phone, ' ', '-', '.', '(', ')')
  p "#{phone}, #{phone.length}"
  if phone.length < 10
    phone = 'invalid-number'
  elsif phone.length == 11
    if phone[0] == '1'
      phone = phone[1..10]
    end
  elsif phone.length > 10
    phone = 'invalid-number'
  else
    phone
  end
  phone
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )
    legislators = legislators.officials
    legislator_names = legislators.map(&:name)
    legislators_string = legislator_names.join(', ')
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letters(id, personal_letter)
  Dir.mkdir('output') unless Dir.exist? 'output'
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts personal_letter
  end

end

template_letter = File.read 'form_letter.html.erb'

erb_template = ERB.new template_letter

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

contents.each do |row|
  id = row[0]

  phone = clean_phone(row[:homephone])

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  personal_letter = erb_template.result(binding)

  save_thank_you_letters(id, personal_letter)

end
