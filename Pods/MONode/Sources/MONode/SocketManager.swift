// Copyright © 2016 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.

import Foundation
import CocoaAsyncSocket

public final class SocketManager: NSObject, GCDAsyncUdpSocketDelegate {
    /// Network configuration.
    public let networkConfiguration: NetworkConfiguration

    /// Delegate.
    public weak var delegate: SocketManagerDelegate?

    /// Current socket status.
    public private(set) var status = Status.idle

    private var socket: GCDAsyncUdpSocket!

    public lazy var deviceID: Int32 = {
        #if os(macOS)
            var deviceName = Host.current().localizedName ?? ""
        #else
            var deviceName = UIDevice.current.name
        #endif
        deviceName = deviceName.replacingOccurrences(of: "MO", with: "")
        if let deviceID = Int32(deviceName) {
            return deviceID
        }
        return Int32(arc4random_uniform(numericCast(Int32.max)))
    }()

    /// Initializes a `SocketManager` with a network configuration.
    public init(networkConfiguration: NetworkConfiguration) {
        self.networkConfiguration = networkConfiguration

        super.init()

        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        socket.setIPv4Enabled(networkConfiguration.enableIPv4)
        socket.setIPv6Enabled(networkConfiguration.enableIPv6)
        open()

        /// Register with hub
        let packet = Packet(type: .handshake, id: deviceID)
        socket.send(packet.serialize() as Data, toHost: networkConfiguration.hubHost, port: networkConfiguration.hubPort, withTimeout: -1, tag: 0)
    }

    /// Closes the socket to stop receving data from the network.
    public func close() {
        socket.close()
        status = .idle
    }

    /// Opens the socket to start receving data from the network.
    public func open() {
        if status != .idle {
            return
        }

        do {
            try socket.enableBroadcast(true)
            try socket.bind(toPort: networkConfiguration.nodePort)
            try socket.beginReceiving()
            status = .bound
        } catch {
            delegate?.handleError("Could not open socket: \(error)")
        }
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        var packet: Packet!
        do {
            packet = try Packet((data as NSData) as Data)
        } catch {
            delegate?.handleError("Could not initialize packet from data: \(error)")
            return
        }

        switch packet.packetType {
        case PacketType.handshake:
            status = .acknowledged

        case PacketType.ping:
            // Reply to pings
            let packet = Packet(type: .ping, id: deviceID)
            socket.send(packet.serialize() as Data, toHost: networkConfiguration.hubHost, port: networkConfiguration.hubPort, withTimeout: -1, tag: 0)

        default:
            delegate?.handlePacket(packet)
        }
    }

    /// Broadcasts a packet to the network.
    public func broadcastPacket(_ packet: Packet) {
        socket.send(packet.serialize() as Data, toHost: networkConfiguration.broadcastHost, port: networkConfiguration.nodePort, withTimeout: -1, tag: 0)
    }
}
