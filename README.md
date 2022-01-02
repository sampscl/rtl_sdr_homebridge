# RTL-SDR Homebridge

Bridge between RTL-SDR and Homebridge; particularly the homebridge mqttthing plugin. This program will listen to radio transmissions with an RTL-SDR, interpret
them, and convert that data into publications on a MQTT bus so that Homebridge can receive data from RF devices that have well-understood protocols but lack an
interface to Homebridge.

Currently, the only supported radio protocol is Honeywell's 345MHz system that is used by numerous Honeywell and Ademco alarm panel systems.

## Dependencies

Before rtl-sdr homebridge will work, the following must be installed:

* [Homebridge](https://homebridge.io)
* [Homebridge mqttthing plugin](https://github.com/arachnetech/homebridge-mqttthing) (this can be installed through the Homebridge GUI)
* [RTL-SDR](https://www.rtl-sdr.com) device
* [rtl_433](https://github.com/merbanan/rtl_433.git)

## Installation
TODO: write installation instructions

## Configuration

RTL-SDR Homebridge is configured with Elixir's standard `runtime.exs` file. The location of this file depends on whether you're running a release or within a
source code repository:

* In a release: `rtl_sdr_homebridge/releases/VERSION/runtime.exs`; replacing VERSION with the version number you're configuring (overlaying new versions over
  old is supported), most likely though there will only be one version present at a time.
* In a source code repository: `config/runtime.exs`

The configuration file itself contains instructions.