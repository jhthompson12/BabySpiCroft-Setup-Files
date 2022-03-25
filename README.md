# BabySpiCroft-Setup-Files
If you are skipping the smart speaker functionality and just want the baby monitor on a Raspberry Pi, skip ahead to [Install Dependencies](https://github.com/jhthompson12/BabySpiCroft-Setup-Files/new/main?readme=1#install-dependencies)

## Set up Picroft
Start with [Picroft image](https://mycroft-ai.gitbook.io/docs/using-mycroft-ai/get-mycroft/picroft#getting-started-with-picroft) burned on to SD Card

## Set up Wi-Fi
Add [wpa_supplicant.conf file](https://www.raspberrypi.com/documentation/computers/configuration.html#adding-the-network-details-to-your-raspberry-pi) to the `/boot` folder on the SD card to enable headless connection to your wifi

## Turn on the Pi and setup Picroft
* Plug it in, turn it on, and let it boot. Then connect via ssh: `ssh pi@<your-raspberry-pi-ip-address>`. The default password is `mycroft`
* Enable the camera interface with `sudo raspi-config` 
* Run through the install prompts, choose the 3.5mm audio output option (unless you’re doing something different). For the microphone, select USB. Dont worry about configuring the mic just yet. Once through the setup, proceed.

## Install Dependencies
Run `sudo apt update`

### GStreamer
```
sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-bad gstreamer1.0-plugins-good gstreamer1.0-alsa
sudo apt install autoconf automake libtool pkg-config libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libraspberrypi-dev
git clone https://github.com/thaytan/gst-rpicamsrc.git
cd gst-raspicamsrc
./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf/
make
sudo make install
cd ..
```        

### Janus
```
sudo apt install libmicrohttpd-dev libjansson-dev \
  libssl-dev libsrtp-dev libsofia-sip-ua-dev libglib2.0-dev \
  libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev \
  libconfig-dev pkg-config gengetopt libtool automake
```           
**If** you are **not** using the Picroft image:
```
apt install git python3-pip
sudo pip3 install meson
sudo apt install -y ninja-build
```       
**If** you are using the Picroft image:
```
pip3 install meson
sudo apt install -y ninja-build
```           

#### Install libnice
```
git clone https://gitlab.freedesktop.org/libnice/libnice
cd libnice
meson --prefix=/usr build && ninja -C build && sudo ninja -C build install
```
#### Install newer version of libsrtp
```
cd ..
wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz
tar xfv v2.2.0.tar.gz
cd libsrtp-2.2.0
sudo apt install openssl
./configure --prefix=/usr --enable-openssl
make shared_library && sudo make install
```

#### Install Janus
```
cd ..
git clone https://github.com/meetecho/janus-gateway.git
cd janus-gateway
sh autogen.sh
./configure --prefix=/opt/janus --disable-websockets --disable-rabbitmq --disable-mqtt --disable-data-channels
make
sudo make install
sudo make configs
```
       
## Final setup 
Clone this project:
```
cd ~
git clone https://github.com/jhthompson12/BabySpiCroft-Setup-Files.git
cd BabySpiCroft-Setup-Files
```

Transfer Alsa configuration file and set up the microphone:

`sudo cp Microphone/asound.conf /etc/`

Add the “listener” setting to .config/mycroft/mycroft.conf so that it looks something like this (just add the "listener" part, don’t change anything else in this file): 
```
{
  "max_allowed_core_version": 21.2,
  "listener": {
    "device_name": "dsnooped"
    }
}
```

Update Janus configuration files:
```
sudo cp Janus/janus.jcfg /opt/janus/etc/janus
sudo cp Janus/janus.plugin.streaming.jcfg /opt/janus/etc/janus
sudo cp Janus/janus.transport.http.jcfg /opt/janus/etc/janus
sudo cp Janus/janus.sh /opt/janus
sudo cp Janus/janus.service /etc/systemd/system
```

Set up the nginx web server
```
sudo apt install nginx
sudo cp nginx/baby-monitor-site /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/baby-monitor-site /etc/nginx/sites-enabled	
sudo rm /etc/nginx/sites-enabled/default\
```               

Move stream services over for `systemctl`
```
sudo cp GStreamer/janus-stream.service /etc/systemd/system
sudo cp GStreamer/janus-stream.sh /etc
```

Set up certificates for https
```
mkdir Monitor_Website_Root/Certs
cd Monitor_Website_Root/Certs
openssl genrsa -out BabySpiCroft.key 2048
openssl req -x509 -new -nodes -key BabySpiCroft.key -sha256 -days 1825 -out BabySpiCroft.pem
```
You will be asked a bunch of questions, you can answer them however you’d like. I responded to the Country, State, and Common Name (as “BabySpiCroft”)
       
Start services
```
cd ~
sudo systemctl start janus.service
sudo systemctl start janus-stream.service
```

## Test it out
If everything is working properly, you should be able to open Google Chrome on your phone or computer and go to `https://<your-rapsberry-pi's-IP-address>

**Bonus steps:**
1. Make the baby monitor services start on boot
```
sudo systemctl enable janus.service
sudo systemctl enable janus-stream.service
```
2. Add a service that turns off the Pi’s LEDs after boot (since they’re pretty bright and this is going in a nursery...)
```
sudo cp Other/disable-led.service /etc/systemd/system
sudo systemctl start disable-led.service
sudo systemctl enable disable-led.service
```
3. Install the created root Certificate on your devices to avoid the pesky "The certificate is not trusted because it is self-signed." errors that you occasionally will have to click through.
