// MainProcess.swift
// Copyright (c) 2023 FastlaneTools

//
//  ** NOTE **
//  This file is provided by fastlane and WILL be overwritten in future updates
//  If you want to add extra functionality to this project, create a new file in a
//  new group so that it won't be marked for upgrade
//

import Foundation
#if canImport(SwiftShell)
    import SwiftShell
#endif

let argumentProcessor = ArgumentProcessor(args: CommandLine.arguments)
let timeout = argumentProcessor.commandTimeout

class MainProcess {
    var doneRunningLane = false
    var thread: Thread!

    @objc func connectToFastlaneAndRunLane(_ fastfile: LaneFile?) {
        runner.startSocketThread(port: argumentProcessor.port)

        let completedRun = Fastfile.runLane(from: fastfile, named: argumentProcessor.currentLane, with: argumentProcessor.laneParameters())
        if completedRun {
            runner.disconnectFromFastlaneProcess()
        }

        doneRunningLane = true
    }

    func startFastlaneThread(with fastFile: LaneFile?) {
        #if !SWIFT_PACKAGE
            thread = Thread(target: self, selector: #selector(connectToFastlaneAndRunLane), object: nil)
        #else
            thread = Thread(target: self, selector: #selector(connectToFastlaneAndRunLane), object: fastFile)
        #endif
        thread.name = "worker thread"
    }
}

public class Main {
    let process = MainProcess()

    public init() {}

    public func run(with fastFile: LaneFile?) {
        process.startFastlaneThread(with: fastFile)

        while !process.doneRunningLane, RunLoop.current.run(mode: RunLoop.Mode.default, before: Date(timeIntervalSinceNow: 2)) {
            // no op
        }
    }
}
