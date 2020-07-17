defprotocol ExGherkin.ParserException do
  def get_message(error)
  def generate_message(error)
  def get_location(error)
end
