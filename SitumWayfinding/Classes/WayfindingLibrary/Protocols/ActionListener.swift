//
//  ActionListener.swift
//  SitumWayfinding
//
//  Created by Lapisoft on 19/1/22.
//

import Foundation

/**
 Protocol to inform of the actual state of a given action
 */
public protocol ActionListener {
    /** Called when action has started */
    func onActionStarted()
    /** Called when action has concluded */
    func onActionConcluded()
    /**
    Called when an error happened on a given actionw
     - Parameter reason: error that happened
    */
    func onActionError(reason: Error)
}

/**
 Action listener that does nothing
 */
internal class EmptyActionListener: ActionListener {
    func onActionStarted() {}

    func onActionConcluded() {}

    func onActionError(reason: Error) {}
}
