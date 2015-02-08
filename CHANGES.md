# 2.0.1

Released 2015-02-08

Fixes:

- In auto-pairing mode, remain connected to current hardware device so long
  as it's within the minimum signal strength threshold

- NVFlash.lit will revert to false when flash timeout occurs on hardware


# 2.0.0

Released 2015-01-04

Version 2 of API. This is a complete rewrite and is not API compatible with version 1.
See the migration guide for how to switch over.

What's new:

- Support for multiple Novas, which can all be monitored
  and controlled individually.
  
- Exposes signal strength.

- Improved distance detection more reliably connects to
  closest Nova.

- Manual connect mode: allow clients full control of
  browsing Novas in range and connecting/disconnecting at
  will.

- Auto connect mode: Simplifies common cases and will
  automatically connect (and reconnect when connection
  lost) to closest Novas. Users can specify how many
  to connect to, tolerance for signal strength.

- Capability to whitelist/blacklist previously seen
  Novas.

- Keep track of whether Nova is lit.

- Easy access to all Novas in range and all connected
  Novas (read array and/or get delegate callbacks).
  
- Separated API into NVFlashService (shared service)
  and NVFlash (each flash).

- Objective-C and Swift friendly.

- Simplified examples in Objective-C and Swift.

----

# 1.0.0

Released 2014-06-01

First stable release. Supports simple API for automatically discovering and connecting
to a single Nova, and controlling the flash.
