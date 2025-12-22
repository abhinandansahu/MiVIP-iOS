//
//  RequestStatusDelegate.swift
//  whitelabel_demo
//

import Foundation
import MiVIPApi

protocol RequestStatusDelegate: AnyObject {
    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?)
    func error(err: String)
}
