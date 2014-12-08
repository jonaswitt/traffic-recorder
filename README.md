Traffic Recorder
================

A Phantom.js based script that records real-time traffic durations between
an origin and a destination (for example, to time commutes)

Getting Started
---------------

The requirement to run this program is Phantom.js (see http://phantomjs.org/ for
details / installation).

To install this program's dependencies, use the node package manager and run
`npm install`

To compile this program, use coffeescript and run `coffee -c traffic.coffee`

To run this program, simply type `phantomjs traffic.js`

Customizing
-----------

You will want to adjust the URLs that are used to query TomTom traffic and
Google Maps with your custom origin and destination.
