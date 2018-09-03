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


## Getting Started

At this point, you will need to have the built computer ready to go.  If you need help with that, and for an overview of the networking hardware involved, see [Part 1](https://renaudcerrato.github.io/2016/05/21/build-your-homemade-router-part1/) of Renaud Cerrato's homemade router guide.

### OS Installation

Install Ubuntu 18.04 Server.  You do not need to set any specific options, just use all of the defaults.  In one of the steps, you will need to create a username and password, but other than that, the defaults are fine.

If you are not sure where to start with this, or need a refresher, check out [this guide from Ubuntu](https://help.ubuntu.com/community/Installation/FromUSBStick).


### Set up the Network Bridge

I have never worked with or even heard of `netplan` before today, but thankfully, documentation and configuration examples were easy to find, and `yaml` files are a bit nicer (to me) than some of the seemingly custom configuration text files I've worked with in the past.  According to `netplan`'s documentation, we can simply put configuration files in the `/etc/netplan` directory, then run `sudo netplan apply`.  I like this approach, because it doesn't require modifying any default system files.

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
sudo apt install -y dnsmasq
```

Take a look at `dhcp-server.sh` to make sure it meets your needs.  If you're not sure, then what is there are sensible defaults, so you can keep it like it is.  When you're ready to test your new DHCP Server, run:

```bash
./dhcp-server.sh
```


## Research Notes

### DHCP Server

Since networking at this level is not in my wheelhouse, I did a small amount of research and it seems that the ISC products and dnsmasq are the most common FOSS DHCP servers that I should consider.  Kea is a replacements for ISC-DHCP, so I really only compared Kea with dnsmasq.  Based on the limited reading and research I have done, I am settling on dnsmasq because a) it is what the 16.04 guide I am using uses, b) it is allegedly best suited for small/home networks, c) is less resource intensive, and d) I didn't find any comments about any major drawbacks that will affect my use case.


## Resources

* https://renaudcerrato.github.io/2016/05/21/build-your-homemade-router-part1/
* https://www.hiroom2.com/2018/05/08/ubuntu-1804-bridge-en/
* https://askubuntu.com/questions/972955/ubuntu-17-10-server-static-ip-netplan-how-to-set-netmask
* https://unix.stackexchange.com/questions/446217/broadcast-and-network-in-netplan
*
