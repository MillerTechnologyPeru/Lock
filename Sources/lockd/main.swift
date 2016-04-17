//
//  main.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/16/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import GATT
import CoreLock

func LockDaemonMain() {
    
    print("Starting Lock Daemon...")
    
    let peripheral = PeripheralManager()
    
    try! peripheral.start()
    
    peripheral
    
    
}

LockDaemonMain()