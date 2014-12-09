
Promise = require 'bluebird'
async = require 'async'
phantom = require 'webpage'
fs = require 'fs'
_ = require 'underscore'
dateformat = require 'dateformat'

log_filename = 'traffic.csv'
if !fs.isFile log_filename
  fs.write log_filename, ['Full Date', 'Hour', 'Direction', 'TomTom', 'Google Maps'].join(';') + "\n", 'a'
console.log 'Writing data to ' + log_filename

tomtom = (direction) ->
  new Promise (resolve) ->
    if direction = 'forth'
      url = 'http://routes.tomtom.com/#/route/Hermannplatz%2520Kreuzberg%252C%2520Berlin%252C%2520DE%254052.487%252C13.42496%2540-1/Ernst-Reuter-Platz%2520Charlottenburg%252C%2520Berlin%252C%2520DE%254052.51199%252C13.32183%2540-1/?leave=now&traffic=true&center=51.323687081829%2C8.7101624999999&zoom=5&map=basic'
    else
      url = 'http://routes.tomtom.com/#/route/Ernst-Reuter-Platz%2520Charlottenburg%252C%2520Berlin%252C%2520DE%254052.51199%252C13.32183%2540-1/Hermannplatz%2520Kreuzberg%252C%2520Berlin%252C%2520DE%254052.487%252C13.42496%2540-1/?leave=now&traffic=true&center=52.500921648076%2C13.3470075&zoom=11&map=basic'
    page = phantom.create();
    page.open url, ->
      page.includeJs "http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js", ->
        setTimeout ->
          totals = page.evaluate ->
            return document.getElementById('routeTotals').textContent

          match = totals.match(/-\s+(\d+)\s+min/);
          if match?
            resolve(match[1])
          else
            html = page.evaluate ->
              document.documentElement.html()
            fs.write 'tomtom-fail.html', html, 'w'
            page.render 'tomtom-fail.png'
            console.error 'Could not get Tomtom traffic data, wrote debug info to tomtom-fail.html/tomtom-fail.png...'
            resolve(null)
          page.close()
        , 2000

gmaps = (direction) ->
  new Promise (resolve) ->
    if direction == 'forth'
      url = 'https://www.google.de/maps/dir/Hermannplatz,+10967+Berlin/Ernst-Reuter-Platz,+10587+Berlin/@52.5007468,13.3284831,13z/data=!3m1!4b1!4m13!4m12!1m5!1m1!1s0x47a84fb782ca9c85:0x3b90d1268fef6a78!2m2!1d13.4249845!2d52.487067!1m5!1m1!1s0x47a8511cf746e4ad:0x9dfe936476372841!2m2!1d13.3215114!2d52.5120351'
    else
      url = 'https://www.google.de/maps/dir/Ernst-Reuter-Platz,+10587+Berlin/Hermannplatz,+10967+Berlin/@52.5007468,13.3284831,13z/data=!4m13!4m12!1m5!1m1!1s0x47a8511cf746e4ad:0x9dfe936476372841!2m2!1d13.3215114!2d52.5120351!1m5!1m1!1s0x47a84fb782ca9c85:0x3b90d1268fef6a78!2m2!1d13.4249845!2d52.487067'
    page = phantom.create();
    page.open url, ->
      page.includeJs "http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js", ->
        setTimeout ->
          totals = page.evaluate ->
            inner = $('#altroute_0 .altroute-aux span')
            if inner.length > 0
              return inner[inner.length - 1].textContent
            inner = $('#altroute_0 .altroute-info span')
            return inner[inner.length - 1].textContent

          match = totals.match(/(\d+)\s+minuten/i);
          if match?
            resolve(match[1])
          else
            html = page.evaluate ->
              document.documentElement.html()
            fs.write 'gmaps-fail.html', html, 'w'
            page.render 'gmaps-fail.png'
            console.error 'Could not get Google Maps traffic data, wrote debug info to gmaps-fail.html/gmaps-fail.png...'
            resolve(null)
          page.close()
        , 2000

queryAll = (direction) ->
  date = new Date()
  console.log 'Querying traffic (' + direction + ') at ' + dateformat(date, 'HH:MM') + '...'
  async.parallel [
    (callback) ->
      tomtom(direction).then (mins) ->
        console.log '  TomTom: ' + mins + ' minutes'
        callback null, { type: 'tomtom', minutes: mins }
    , (callback) ->
      gmaps(direction).then (mins) ->
        console.log '  Google Maps: ' + mins + ' minutes'
        callback null, { type: 'gmaps', minutes: mins }
  ], (err, results) ->
    tomtom_time = _.find results, (entry) -> entry.type == 'tomtom'
    gmaps_time = _.find results, (entry) -> entry.type == 'gmaps'

    simpledate = date.getHours() + date.getMinutes() / 60 + date.getSeconds() / 3600
    record = [dateformat(date, 'dd.mm.yyyy HH:MM:ss Z'), simpledate, direction, tomtom_time.minutes, gmaps_time.minutes]
    fs.write log_filename, record.join(';') + "\n", 'a'

queryAllTimeDependent = ->
  date = new Date()
  hour = date.getHours()
  if hour >= 6 && hour <= 11
    queryAll('forth')
  else if hour >= 15 && hour <= 20
    queryAll('back')
  else
    console.log '(skipping query at ' + dateformat(date, 'HH:MM') + ')'

queryAllTimeDependent()
setInterval ->
  queryAllTimeDependent()
, 5 * 60 * 1000
