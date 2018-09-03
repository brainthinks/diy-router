# DIY Router

@TODO - write the purpose of this project.

So before you embark on this journey, I recommend mapping out what you want your network to look like.  Below is the network diagram I will be using.


## Network Diagram

I recommend you have a network diagram of your own.  You can certainly use mine, and I think this one will applicable to most situations.  However, if you know your network will be more complicated than this, or will have different components or something, I recommend making a diagram of your network as the first step.

 - fios goes into modem
 - modem talks to custom router
 - custom router is dhcp server
 - custom router handles wifi
 - custom router has one port out to a switch
 - switch handles wired connections

@TODO - make this a graphic


## Bill of Materials

* Ubuntu 18.04 Server
* specific Airetos card
* two ethernet ports

If you want to use Ubuntu 16.04, don't follow my tutorial.  See Renaud Cerrato's tutorial instead - [https://renaudcerrato.github.io/2016/05/21/build-your-homemade-router-part1/](https://renaudcerrato.github.io/2016/05/21/build-your-homemade-router-part1/).


## Basic Commands

During the course of this project, you will need to know a few commands to be able to troubleshoot and to identify the things you are working with.  Here are the ones I used.

ifconfig -a
iw list | less
less /etc/netplan
ip route show default

linksys router default credentials: admin / admin

To find out what things are listening on what ports, run

sudo netstat -utlnp | grep :[port]

To find out what processes are running, run

ps -aux | grep [pid]



## Getting Started

At this point, you will need to have the built computer ready to go.  If you need help with that, and for an overview of the networking hardware involved, see [Part 1](https://renaudcerrato.github.io/2016/05/21/build-your-homemade-router-part1/) of Renaud Cerrato's homemade router guide.

### OS Installation

Install Ubuntu 18.04 Server.  You do not need to set any specific options, just use all of the defaults.  In one of the steps, you will need to create a username and password, but other than that, the defaults are fine.

If you are not sure where to start with this, or need a refresher, check out [this guide from Ubuntu](https://help.ubuntu.com/community/Installation/FromUSBStick).

Once you have finished installing, I advise you to upgrade available packages.

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

### Set up the Network Bridge

I have never worked with or even heard of `netplan` before today, but thankfully, documentation and configuration examples were easy to find, and `yaml` files are a bit nicer (to me) than some of the seemingly custom configuration text files I've worked with in the past.  According to `netplan`'s documentation, we can simply put configuration files in the `/etc/netplan` directory, then run `sudo netplan apply`.  I like this approach, because it doesn't require modifying any default system files (even though we'll have to that later).

Take a look at the `netplan.diy_router_bridge.config.yaml` file.  The only things you should have to change are the interfaces.

@TODO - talk about how to determine which interface is which, and which two need to be bridged


```bash
sudo cp netplan.diy_router_bridge.config.yaml /etc/netplan
sudo netplan apply
```

### Set up the DHCP Server

The DHCP Server is the thing that gives the internet-connected devices in our home an IP address (in most cases).  We need to set one up for ourselves, since we want our custom router to be in control of providing the network connection to all of the devices in our home.

We'll be using `dnsmasq` as our DHCP Server.  Install it:


```bash
sudo apt install -y dnsmasq*
```

Take a look at `dhcp-server.sh` to make sure it meets your needs.  If you're not sure, then what is there are sensible defaults, so you can keep it like it is.

Now, we have to ensure `systemd-resolved` will not create a conflict with our "custom" `dnsmasq`.  You will need to edit the `resolved` configuration by running `sudo nano /etc/systemd/resolved.conf`, and addding the line `DNSStubListener=udp` at the bottom of the file.  Finally, restart the service by running `sudo systemctl restart systemd-resolved.service`.

When we do this, we are in effect removing the default domain name resolver (DNS).  It is useful to still be able to access places on the internet by their domain names, so let's fix this now.  `sudo nano /etc/netplan/50-cloud-init.yaml`, and add the following configuration to the network interface that is actually connected to the internet:

```
nameservers:
  # Cloudflare
  addresses: [1.1.1.1, 1.0.0.1]
  # Google
  addresses: [8.8.8.8, 8.8.4.4]
```

Then run `sudo netplan apply`.

Finally, we are ready to run our "custom" `dnsmasq`:

```bash
sudo ./dhcp-server.sh
```

At this point, it is probably a good idea to make sure everything is working properly.  Here is what I did.

1. `sudo systemctl restart systemd-resolved.service` to ensure the `systemd-resolvd` is still running
1. `sudo netstat -utlnp | grep :53` to ensure `systemd-resolved` is using port 53 over UDP and `dnsmasq` is using port 53 over TCP
1. Plug a laptop or some other computer into the second network port on my custom router computer
1. Ensure said laptop receives a network connection
1. `ifconfig -a` on the laptop to ensure my ip address is in the correct range (by default, you should have an ip address between 192.168.2.25 and 192.168.2.90)
1. `ip route show default` to ensure the ip address came from 192.168.2.1

If everything looks good, let's move on to the next section.

### Set up Routing

If you're following along, this step will be complete when our laptop wtih a wired connection to our custom router is able to get on the internet.

Run `sudo sysctl -w net.ipv4.ip_forward=1` to enable our bridge to get on the internet.  We also want this to persist when the machine is restarted, so we'll need to edit `/etc/sysctl.conf`.  Open that file with `sudo nano /etc/sysctl.conf`, then find and uncommend the line that contains the `net.ipv4.ip_forward=1` configuration.

Renaud Cerrato's guide says that configuring IPTABLES is hard, so I'm not even going to try.  Instead, he recommends using a program called `firehol`.  This program is part of the `universe` repository, so we have to enable that first:

```bash
sudo add-apt-repository universe
sudo apt update
sudo apt install -y firehol*
sudo mv /etc/firehol/firehol.conf /etc/firehol/firehol.conf.bak
sudo cp firehol.conf /etc/firehol/
sudo systemctl restart firehol.service
```

You'll also need to configure `firehol` to start at start up.  `sudo nano /etc/default/firehol`, set the line to `START_FIREHOL=YES`.

At this point, I restarted.  Maybe you don't have to, but I wanted to be sure that firehol and everything else we've loaded thus far were in working order.  If you do restart the machine, don't forget to manually run `sudo ./dchp-server`!  We'll get to setting that up to run at startup later.

You should now be able to get on the internet with your wired laptop!  Next, we'll get that laptop on the internet wirelessly.

### Set up the Access Point

Continuing to follow Renaud's original guide, we'll be using `hostapd` to manage the access point.  I did try to have `netplan` do this on its own, because the documentation makes the configuration look simple, but unfortunately the wifi access point configuration will not work on Ubuntu Server 18.04 because the access point mode requires `network-manager`, which is not something we have by default, and not something that is worth the trouble to install (based on what I've read - even Renaud's guide has you uninstall it from 16.04).  Let's get `hostapd` installed:

```bash
sudo apt install -y hostapd --fix-missing
```






## Research Notes

### DHCP Server

Since networking at this level is not in my wheelhouse, I did a small amount of research and it seems that the ISC products and dnsmasq are the most common FOSS DHCP servers that I should consider.  Kea is a replacements for ISC-DHCP, so I really only compared Kea with dnsmasq.  Based on the limited reading and research I have done, I am settling on dnsmasq because a) it is what the 16.04 guide I am using uses, b) it is allegedly best suited for small/home networks, c) is less resource intensive, and d) I didn't find any comments about any major drawbacks that will affect my use case.

Another big issue for me getting `dnsmasq` to work was its conflict with `systemd-resolved`.  By default in the Ubuntu 18.04 version that I have installed, `systemd-resolved` listens on `127.0.0.53:53` by default, and for whatever reason this conflicts with `dnsmasq`, or at least with the way I have it configured.  It seems that this was a problem other people had to (check the links in the Resources section below).  It seems that right now, the `systemd-resolved` option of `DNSStubListener` is undocumented.  I was able to find the options buried in a github issue comment.  Solving that one took a while.  I got lucky, because as of the time of this writing, the comment that contains the valid enum options was made just 10 days ago!  Also, modifying this gets rid of the default DNS resolution (or something like that), so you appear to lose your internet connection.  Re-instating the `nameservers` property in `netplan` was something I had to figure out on my own.  Thankfully, it is well documented and in many of the examples I looked at.

By far, the biggest problem I ran into was an issue where every sudo command got slow, and every network request took a long time to initialize.  Sometimes, the network requests would fail, and after a while, the domain name resolution was failing every time.  This turned out to be an issue with the IP address I had chosen for my network bridge - you MUST create the bridge on a different subnet!  Meaning that if you are getting your internet from 192.168.1.1, you cannot use 192.168.1.x!  That is why all of my default configurations are 192.168.2.x.


## Resources

* https://renaudcerrato.github.io/2016/05/21/build-your-homemade-router-part1/
* https://www.hiroom2.com/2018/05/08/ubuntu-1804-bridge-en/
* https://askubuntu.com/questions/972955/ubuntu-17-10-server-static-ip-netplan-how-to-set-netmask
* https://unix.stackexchange.com/questions/446217/broadcast-and-network-in-netplan
* https://github.com/systemd/systemd/pull/4061
* https://github.com/moby/moby/issues/32545
* https://blog.cloudflare.com/announcing-1111/
* https://developers.google.com/speed/public-dns/
* https://launchpad.net/ubuntu/+archivemirrors
* https://launchpad.net/ubuntu/+mirror/mirror.cs.jmu.edu-archive
* https://askubuntu.com/questions/1061504/ubuntu-server-18-04-lts-as-wifi-access-point
*
