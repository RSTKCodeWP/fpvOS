#!/bin/sh
# Optional VTX-side helper. The air UART bypass is enabled by stock ar_ldyhs_sky
# when the goggles send sky command 42 / mode 2 (ELRS passthrough). fpvOS on
# the VRX sends that automatically in MAVLink control mode after link-up.
#
# This hook only logs that the FC control UART should be wired to UART A on
# the VTX (420000 CRSF). It does not replace ar_ldyhs_sky.
LOG=/usrdata/fpv/uart_bypass.log
echo "$(date): uart bypass hook (cmd42 from VRX expected)" >> "$LOG" 2>/dev/null
