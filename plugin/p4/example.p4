#include <core.p4>
#include <xsa.p4>

typedef bit<48>  MacAddr;
typedef bit<32>  IPv4Addr;

const bit<16> IPV4_TYPE  = 0x0800;

// ****************************************************************************** //
// *************************** H E A D E R S  *********************************** //
// ****************************************************************************** //

header eth_mac_t {
    MacAddr dmac; // Destination MAC address
    MacAddr smac; // Source MAC address
    bit<16> type; // Tag Protocol Identifier
}

header ipv4_t {
    bit<4>   version;  // Version (4 for IPv4)
    bit<4>   hdr_len;  // Header length in 32b words
    bit<8>   tos;      // Type of Service
    bit<16>  length;   // Packet length in 32b words
    bit<16>  id;       // Identification
    bit<3>   flags;    // Flags
    bit<13>  offset;   // Fragment offset
    bit<8>   ttl;      // Time to live
    bit<8>   protocol; // Next protocol
    bit<16>  hdr_chk;  // Header checksum
    IPv4Addr src;      // Source address
    IPv4Addr dst;      // Destination address
}

// ****************************************************************************** //
// ************************* S T R U C T U R E S  ******************************* //
// ****************************************************************************** //

// header structure
struct headers {
    eth_mac_t    eth;
    ipv4_t       ipv4;
}

// User metadata structure
//
// Note:
//   - The total bits of user metadata should be greator or equal to 64
struct metadata {
    bit<16> tuser_src;
    bit<16> ingress_port;
    bit<16> egress_spec;
    bit<16> padding;
    bit<32> g32_01;
    bit<32> g32_02;
    bit<64> g64_01;
}

// ****************************************************************************** //
// *************************** P A R S E R  ************************************* //
// ****************************************************************************** //

parser MyParser(packet_in packet, 
                out headers hdr, 
                inout metadata meta, 
                inout standard_metadata_t smeta) {
    
    state start {
        transition parse_eth;
    }
    
    state parse_eth {
        packet.extract(hdr.eth);
        transition select(hdr.eth.type) {
            IPV4_TYPE : parse_ipv4;
            default   : accept; 
        }
    }
    
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

// ****************************************************************************** //
// **************************  P R O C E S S I N G   **************************** //
// ****************************************************************************** //

control MyProcessing(inout headers hdr, 
                     inout metadata meta, 
                     inout standard_metadata_t smeta) {
                      
    action forwardPacket(bit<16> port) {
        meta.egress_spec = port;
    }
    
    action dropPacket() {
        smeta.drop = 1;
    }

    table forwardIPv4 {
        key             = { hdr.ipv4.dst : lpm; }
        actions         = { forwardPacket; 
                            dropPacket; }
        size            = 1024;
		num_masks       = 64;
        default_action  = dropPacket;
    }

    apply {
        if (smeta.parser_error != error.NoError) {
            dropPacket();
            return;
        }
        
        if (hdr.ipv4.isValid())
            forwardIPv4.apply();
        else
            dropPacket();
    }
} 

// ****************************************************************************** //
// ***************************  D E P A R S E R  ******************************** //
// ****************************************************************************** //

control MyDeparser(packet_out packet, 
                   in headers hdr,
                   inout metadata meta, 
                   inout standard_metadata_t smeta) {
    apply {
        packet.emit(hdr.eth);
        packet.emit(hdr.ipv4);
    }
}

// ****************************************************************************** //
// *******************************  M A I N  ************************************ //
// ****************************************************************************** //

XilinxPipeline(
    MyParser(), 
    MyProcessing(), 
    MyDeparser()
) main;

