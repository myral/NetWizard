#!/usr/bin/env ruby

# Passive Arp Monitor
# Analyze ARP traffic and extract some useful info
# Usage: arp_monitor("eth0"[, 0])



require_relative './arp_params.rb'
require 'json'

def arp_monitor(eth,verb, count) 
  
  pairs = Hash.new  
  pairs["module"]="Arp_Monitor"
  pairs["data"]= {}
  
  # Traps INT signal.. it's better to exit cleanly ;)
  trap "SIGINT" do
    return pairs.to_json
    # puts "Exiting..."
    # break
  end
  
  if count == '0' 
    guard = -1
  else  
    guard = count.to_i
  end

  # Init capture with static filter "ARP" and parses packets
  cap = PacketFu::Capture.new(:iface => eth, :filter => 'arp', :start => true)
  cap.stream.each do |p|
    pkt = PacketFu::Packet.parse p

    packet_info = [
      pkt.arp_saddr_ip, 
      pkt.arp_saddr_mac, 
      pkt.arp_daddr_ip, 
      pkt.arp_daddr_mac, 
      pkt.arp_hw_len, 
      pkt.arp_proto,
      pkt.arp_proto_len, 
      ArpParams::ARP_HWTYPES[pkt.arp_hw], 
      ArpParams::ARP_OPCODES[pkt.arp_opcode], 
      pkt.arp_header.body]
    
    # Creates an hash with ip-mac pairs and checks if something was wrong ;)
    if (pairs["data"].has_key?(pkt.arp_saddr_ip))
      if not (pairs["data"][pkt.arp_saddr_ip] == pkt.arp_saddr_mac)
        puts "ARP SPOOFING DETECTED: $#{pkt.arp_saddr_ip}"
      end
    else
      pairs["data"][pkt.arp_saddr_ip] = pkt.arp_saddr_mac
    end
      
    # Are you verbose? 
    if verb == 0 # if not only some packet informations
		  puts "%-15s %-17s -> %-15s %-17s %s %s %s %s %s" % packet_info
    else
      if verb != "silent" # else if not silent all the packet
        puts "---------------------------------------"
        pp packet_info
      end
    end
puts guard
    guard = guard - 1
    break if guard == 0

  end

  return pairs.to_json
end
