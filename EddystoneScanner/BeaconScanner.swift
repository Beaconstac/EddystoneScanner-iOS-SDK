//
//  BeaconScanner.swift
//  NearbyReplica
//
//  Created by Amit Prabhu on 27/11/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import CoreBluetooth

///
/// BeaconScannerDelegate
///
/// Implement this to receive notifications about beacons.
public protocol BeaconScannerDelegate {
    func didFindBeacon(beaconScanner: BeaconScanner, beacon: Beacon)
    func didLoseBeacon(beaconScanner: BeaconScanner, beacon: Beacon)
    func didUpdateBeacon(beaconScanner: BeaconScanner, beacon: Beacon)
}

///
/// BeaconScanner
///
/// Scans for Eddystone compliant beacons using Core Bluetooth. To receive notifications of any
/// sighted beacons, be sure to implement BeaconScannerDelegate and set that on the scanner.
///
public class BeaconScanner: NSObject, CBCentralManagerDelegate {
    
    public var delegate: BeaconScannerDelegate?
    
    /// Beacons that are close to the device.
    /// Keeps getting updated. Beacons are removed periodically after no packets being recieved for 1 minuite
    ///
    public var nearbyBeacons = [Beacon]()
    
    private var centralManager: CBCentralManager!
    private let beaconOperationsQueue: DispatchQueue = DispatchQueue(label: "com.nearbyservice.queue.beaconscanner")
    private var shouldBeScanning: Bool = false
    
    private var beaconTelemetryCache = [UUID: Data]()
    private var beaconURLCache = [UUID: URL]()
    
    private var timer: DispatchTimer?
    
    public override init() {
        super.init()
        
        self.centralManager = CBCentralManager(delegate: self, queue: self.beaconOperationsQueue)
        self.timer = DispatchTimer(repeatingInterval: 10.0)
        self.timer?.delegate = self
    }
    
    /**
     Start scanning. If Core Bluetooth isn't ready for us just yet, then waits and THEN starts scanning
    */
    public func startScanning() {
        self.beaconOperationsQueue.async { [weak self] in
            self?.startScanningSynchronized()
            self?.timer?.startTimer()
        }
    }
    
    /**
     Stops scanning for beacons
     */
    public func stopScanning() {
        self.beaconOperationsQueue.async { [weak self] in
            self?.centralManager.stopScan()
        }
    }
    
    
    /**
     Starts scanning for beacons
     */
    private func startScanningSynchronized() {
        if self.centralManager.state != .poweredOn {
            print("CentralManager state is %d, cannot start scan", self.centralManager.state.rawValue)
            self.shouldBeScanning = true
        }
        else {
            print("Starting to scan for Eddystones")
            let services = [CBUUID(string: "FEAA")]
            let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
            self.centralManager.scanForPeripherals(withServices: services, options: options)
        }
    }

    ///
    /// MARK - Delegate callbacks
    ///
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && self.shouldBeScanning {
            self.startScanningSynchronized();
        }
    }
    
    ///
    /// Core Bluetooth CBCentralManager callback when we discover a beacon. We're not super
    /// interested in any error situations at this point in time.
    ///
    public func centralManager(_ central: CBCentralManager,
                                didDiscover peripheral: CBPeripheral,
                                advertisementData: [String : Any],
                                rssi RSSI: NSNumber) {
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey]
            as? [NSObject : AnyObject] else {
            return
        }
        
        // Get beacon index from the beacon list
        let beaconIndex = self.nearbyBeacons.index(where: {$0.identifier == peripheral.identifier})
        
        let frameType = Eddystone.frameTypeForFrame(advertisementFrameList: serviceData)
        switch frameType {
        case .telemetry:
            let telemetryData = Eddystone.telemetryDataForFrame(advertisementFrameList: serviceData)
            let eddystoneURL = self.beaconURLCache[peripheral.identifier]
            
            // Stash away the telemetry data for later use
            beaconTelemetryCache[peripheral.identifier] = telemetryData
            guard let index = beaconIndex else {
                break
            }
            
            // Save the changing beacon data into the beacon object
            let beacon = self.nearbyBeacons[index]
            beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
            self.addBeacon(beacon: beacon, atIndex: index)
            
            self.delegate?.didUpdateBeacon(beaconScanner: self, beacon: beacon)

        case .uid, .eid:
            let telemetryData = self.beaconTelemetryCache[peripheral.identifier]
            let eddystoneURL = self.beaconURLCache[peripheral.identifier]
            
            guard let index = beaconIndex else {
                // Newly discovered beacon. Create a new beacon object
                let beaconServiceData = serviceData[Eddystone.ServiceUUID] as? Data
                guard let beacon = Beacon(identifier: peripheral.identifier,
                                          frameData: beaconServiceData,
                                          rssi: RSSI.intValue) else {
                                            break
                }
                beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
                self.appendBeacon(beacon: beacon)
                
                self.delegate?.didFindBeacon(beaconScanner: self, beacon: beacon)
                break
            }
            
            // Beacon already discovered. Update telemetry data
            let beacon = self.nearbyBeacons[index]
            beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
            self.addBeacon(beacon: beacon, atIndex: index)
            
            self.delegate?.didUpdateBeacon(beaconScanner: self, beacon: beacon)
            
        case .url:
            let telemetryData = self.beaconTelemetryCache[peripheral.identifier]
            let eddystoneURL = Eddystone.parseURLFromFrame(advertisementFrameList: serviceData)
            
            // Stash away the URL for later use
            self.beaconURLCache[peripheral.identifier] = eddystoneURL
            
            guard let index = beaconIndex else {
                break
            }
            
            // Update the beacon object
            let beacon = self.nearbyBeacons[index]
            beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
            self.addBeacon(beacon: beacon, atIndex: index)
            
            self.delegate?.didUpdateBeacon(beaconScanner: self, beacon: beacon)
            
        default:
            print("Unable to find service data; can't process Eddystone")
        }
    }
    
}

extension BeaconScanner {
    // MARK: Sync functions
    private static func sync(obj: Any, closure: () -> Void) {
        objc_sync_enter(obj)
        closure()
        objc_sync_exit(obj)
    }
    
    private func appendBeacon(beacon: Beacon) {
        BeaconScanner.sync(obj: self.nearbyBeacons) {
            self.nearbyBeacons.append(beacon)
        }
    }
    
    private func addBeacon(beacon: Beacon, atIndex index: Int) {
        BeaconScanner.sync(obj: self.nearbyBeacons) {
            self.nearbyBeacons[index] = beacon
        }
    }
}

extension BeaconScanner: DispatchTimerProtocol {
    func timerCalled(dispatchTimer: DispatchTimer?) {
        BeaconScanner.sync(obj: self.nearbyBeacons) {
            // Loop through the beacon list and find which beacon has not been seen in the last 15 seconds
            // Mutation of array in-place
            self.nearbyBeacons = self.nearbyBeacons.filter({ (beacon) -> Bool in
                if Date().timeIntervalSince1970 - beacon.lastSeen.timeIntervalSince1970 > 15  {
                    self.delegate?.didLoseBeacon(beaconScanner: self, beacon: beacon)
                    return false
                }
                return true
            })
        }
    }
}

