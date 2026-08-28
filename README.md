
# Huawei audio fix

A small fix script for the Huawei MateBook D15 BOD-WXX9 on Kali Linux and other Debian-based systems.

On this model, the Intel Tiger Lake audio controller is detected, but the laptop firmware does not bring up the I2C link used by the ES8336 codec. As a result, the SOF driver waits for the codec indefinitely and Linux does not create a usable sound card.

The script switches the system to the HDA audio path. This restores the built-in speakers and headphone jack, adds a compatible firmware filename, and disables an old Huawei headphone monitor that conflicts with the missing SOF card.

## Usage

```bash
chmod +x huawei-audio-fix.sh
sudo ./huawei-audio-fix.sh
sudo reboot
```

After reboot, check the result with:

```bash
aplay -l
wpctl status
```

## Known limitation

The internal microphone may not work or may record silence. In HDA mode, it cannot access the ES8336 digital microphone. A USB headset, external USB microphone, or Bluetooth headset can be used for recording. Fully restoring the built-in microphone requires an ACPI/BIOS fix or a kernel patch for the specific motherboard revision.

The script checks for audio controller `8086:a0c8` and exits on other hardware.

## Tested on

The script was tested on:

- Huawei MateBook D15 2021, Intel Core i3-1115G4;
- motherboard with PCI subsystem `QUANTA 152d:127d`;
- Kali Linux Rolling 2026.3;
- kernel `7.1.5+kali-amd64`;
- PipeWire 1.6.8 and WirePlumber 0.5.15;
- Intel audio controller `8086:a0c8`.

After reboot, speakers, headphones, and an analog capture device appeared. The built-in microphone still recorded silence because the ES8336 ACPI/I2C connection is not exposed by the firmware.

The BOD-WXX9-PCB-B4 and BOD-WXX9-PCB-B5 revisions are very similar, but were not tested separately with this script.
