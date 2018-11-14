// Copyright © 2017 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.

/// Specifies the network configuration
public struct NetworkConfiguration {
    /// IP addess of the hub.
    public var hubHost = "10.0.0.1"

    /// IP port of the hub.
    public var hubPort = UInt16(10101)

    /// Broadcast IP address, depends on router settings.
    public var broadcastHost = "10.0.0.255"

    /// IP port of the nodes.
    public var nodePort = UInt16(11111)

    /// How often to ping nodes, in seconds.
    public var pingInterval = 0.5

    /// How long to wait for a node to respond to a ping, in seconds.
    public var pingTimeout = 5.0

    public var enableIPv4 = true
    public var enableIPv6 = false

    public init() {}
}
