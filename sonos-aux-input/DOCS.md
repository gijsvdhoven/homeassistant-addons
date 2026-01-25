# Sonos AUX Input

Stream audio from a USB sound card to your Sonos speakers using Darkice and Icecast2.

This addon captures audio from a USB sound card connected to your Home Assistant server and streams it as an MP3 stream that Sonos can play. This allows you to add AUX input capability to your Sonos system - connect a turntable, CD player, or any other audio source to your USB sound card.

## Requirements

- A USB sound card with audio input (e.g., Behringer UCA202, UCA222, or similar)
- Home Assistant OS or Supervised installation
- Sonos speakers on the same network

## Installation

1. Add this repository to your Home Assistant addon store
2. Install the "Sonos AUX Input" addon
3. Connect your USB sound card to your Home Assistant server
4. Configure the addon (see below)
5. Start the addon
6. Add the stream URL to your Sonos system

## Configuration

### Audio Settings

Click the **Audio** tab in the addon configuration and select your USB sound card as the **Input** device. The **Output** setting is not used by this addon.

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `stream_name` | AUX Input | Name shown for the stream in Sonos |
| `stream_description` | Auxiliary audio input stream | Description of the stream |
| `stream_genre` | Various | Genre tag for the stream |
| `bitrate` | 320 | Audio bitrate in kbps (64-320) |
| `port` | 8010 | Port for the Icecast streaming server |
| `icecast_password` | hackme | Password for Icecast authentication |
| `mount_point` | aux.mp3 | URL path for the stream |

## Adding the Stream to Sonos

Once the addon is running, check the addon logs for the stream URL (e.g., `http://192.168.1.100:8010/aux.mp3`).

### Using Sonos Desktop App (Windows/Mac)

1. Open the Sonos desktop app
2. Go to **Manage** -> **Add Radio Station**
3. Enter the stream URL from the addon logs
4. Give it a name (e.g., "AUX Input")
5. Click **OK**

The station will appear in **My Sonos** -> **Stations**.

### Using Sonos Mobile App

1. Go to **Browse** -> **TuneIn** -> **My Radio Stations**
2. Add a new station with your stream URL

## Troubleshooting

### No audio input detected

- Make sure your USB sound card is connected before starting the addon
- Check that you've selected the correct input device in the Audio tab
- Try restarting the addon after connecting the sound card
- Check the addon logs for available audio devices

### Stream URL not working in Sonos

- Make sure your Home Assistant and Sonos are on the same network
- Verify the addon is running and check the logs for the correct URL
- Try accessing the Icecast status page in a browser (e.g., `http://192.168.1.100:8010/`)
- Check that the configured port is not blocked by a firewall

### Port already in use

- Change the `port` option to a different value (e.g., 8011, 8020)
- Make sure no other service is using the same port

### Audio quality issues

- Increase the `bitrate` setting (max 320 kbps)
- Check your USB sound card connections
- Ensure the audio source volume is set appropriately

## Technical Details

This addon uses:

- **Icecast2**: A streaming media server that serves the audio stream
- **Darkice**: A live audio encoder that captures from PulseAudio and sends to Icecast
- **PulseAudio**: Home Assistant's audio system for device access

The audio is encoded as MP3 at the configured bitrate with a sample rate of 44100 Hz (CD quality).

## Support

For issues and feature requests, please visit the [GitHub repository](https://github.com/gijsvdhoven/homeassistant-addons).
