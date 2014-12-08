
xlsx = require 'node-xlsx'
_ = require 'underscore'
fs = require 'fs'
moment = require 'moment'

weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
date_format = 'DD.MM.YYYY HH:mm:ss Z'

last_direction = null
last_date = null
current_section = []
sections = []

processSection = (section, direction, date) ->
  return if !section? || section.length == 0
  console.log 'New section ' + direction + ' with date ' + date
  weekday = weekdays[date.getDay()]
  day = date.getDate()
  section_name = direction + ' ' + weekday + ' ' + day
  data = _.map section, (row) ->
    [row.hour, row.tomtom || null, row.gmaps || null]
  data.unshift ['Hour', 'Tomtom', 'Google Maps']
  sections.push { name: section_name, data: data }

csv_content = fs.readFileSync 'traffic.csv', encoding: 'utf8'
for csv_line in csv_content.split("\n")
  csv_fields = csv_line.split(';')
  continue if csv_fields.length < 5 || csv_fields[1] == 'Hour'
  direction = csv_fields[2]
  if direction != last_direction
    processSection(current_section, last_direction, moment(last_date, date_format).toDate())
    current_section = []
  current_section.push({ hour: parseFloat(csv_fields[1]), tomtom: parseInt(csv_fields[3]), gmaps: parseInt(csv_fields[4]) })
  last_direction = direction
  last_date = csv_fields[0]
processSection(current_section, last_direction, moment(last_date, date_format).toDate())

buffer = xlsx.build(sections)
fs.writeFileSync('traffic.xlsx', buffer)
