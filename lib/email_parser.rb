# Build a class EmailAddressParser that accepts a string of unformatted 
# emails. The parse method on the class should separate them into
# unique email addresses. The delimiters to support are commas (',')
# or whitespace (' ').

class EmailParser
  attr_accessor :email
  attr_writer :date

  def initialize(email, id=nil)
    @email = Mail.read_from_string email
    @id = id
  end

  delegate :to => :email

  def text
    return @email.text_part.decoded if !@email.text_part.blank? && @email.text_part.decoded
    return HTML::FullSanitizer.new.sanitize @email.body.to_s if !@email.body.blank?
    ""
  end

  def subject
    email.subject || @email['Subj'].to_s # aol forwards
  end

  def name_to
    get_field('to', :display_names).to_s
  end

  def name_from
    get_field('from', :display_names).to_s
  end

  def message_id
    @id || @email.message_id
  end

  def to
    get_field('to', :addresses) || @email['to'].to_s
  end

  def from
    get_field('from', :addresses) || @email['from'].to_s
  end

  def date
    @date ||= @email.date || @email['Sent'].to_s.to_datetime
  end

  def forward
    match = text.scan(/(^[>\w\s]*?): \w*?/).flatten.first
    t = text.split(match) # split out forwards
    t = [t.pop] if t.length > 1
    text = ("#{match}" + t.join("\n")).strip.lines.map {|l| l.gsub(/^[> ]*/, '').gsub("\r", '') }.join
    p  text
    new_email = EmailParser.new text, message_id # pass along the id from the parent

    new_email.date = date if !new_email.date.nil? && new_email.date.hour == 0 && new_email.date.min == 0

    return new_email if new_email.date

    self
  end

  private

  def get_field(field, send)
    @email[field].send(send).first if @email[field] && @email[field].errors.blank?
  end
end