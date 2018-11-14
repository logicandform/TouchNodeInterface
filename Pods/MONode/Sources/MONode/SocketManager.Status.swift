// Copyright © 2017 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.

extension SocketManager {
    public enum Status {
        /// The socket is not receiving data from the network. Default status.
        case idle

        /// The socket is receiving data from the network, but hasn't been acknowledged by the hub.
        case bound

        /// An acknowledgement was received from the hub.
        case acknowledged
    }
}
