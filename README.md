# ec-phoebus
A container image for the Phoebus OPI tool for EPICS

To launch:
```bash
curl -O https://raw.githubusercontent.com/epics-containers/ec-phoebus/main/phoebus.sh
bash phoebus.sh
```

To change settings:
```bash
curl -O https://raw.githubusercontent.com/epics-containers/ec-phoebus/main/settings/settings.ini
# edit settings.ini as needed
# the script will detect the settings.ini in the same folder and mount it into the container
bash phoebus.sh
```

For the full set of settings available see [Phoebus Settings Documentation](https://control-system-studio.readthedocs.io/en/latest/preference_properties.html).

## Issues with local IOCs serving PVA PVs:

If you are running a local IOC and having issues with the PVA PVs not being found, you may need to adjust the settings.ini file to set the PVA name server to localhost.

Get settings.ini as above and uncomment this line:
```ini
org.phoebus.pv.pva/epics_pva_name_servers=127.0.0.1
```
