#!/usr/bin/env ruby
#
# Prints current EVE PI material quantities into per-planet CSV files
#
# Designed to create a historic record for charting over time.  It sums the
# quantities per material type for an entire planet, creates one column per
# material type and logs a single entry each time it's run.  Per planet files
# allow some level of detail and can be aggregated outside of the script.

require 'eaal'

fail('Usage: pi_logger.rb user_id char_id') unless ARGV.count == 2
fail('Set EVE_API_KEY environment variable') if ENV['EVE_API_KEY'].nil?

char_id = ARGV[1]
api = EAAL::API.new(ARGV[0], ENV['EVE_API_KEY'], 'char')
time = Time.now.to_i

api.PlanetaryColonies(:characterID => char_id).colonies.each do |colony|
  csv = "#{colony.planetID}.csv"
  if File.exist?(csv)
    file = File.read(csv).lines.map { |l| l.chomp }.to_a
    headers = file.shift.split(',')
    quantities = [0]*headers.size
    quantities[0] = time
  else
    headers = ['time']
    quantities = [time]
  end

  api.PlanetaryPins(:characterID => char_id, :planetID => colony.planetID).pins.each do |pin|
    next if pin.contentQuantity.to_i == 0

    if (idx = headers.index(pin.contentTypeName))
      quantities[idx] = quantities[idx].to_i + pin.contentQuantity.to_i
    else
      headers << pin.contentTypeName
      quantities << pin.contentQuantity
    end
  end

  File.write(csv, [headers.join(','), file, quantities.join(',')].flatten.compact.join("\n"))
end
