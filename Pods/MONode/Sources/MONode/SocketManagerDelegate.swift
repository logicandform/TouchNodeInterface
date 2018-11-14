// Copyright © 2017 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.

public protocol SocketManagerDelegate: class {
    func handleError(_ message: String)
    func handlePacket(_ packet: Packet)
}
