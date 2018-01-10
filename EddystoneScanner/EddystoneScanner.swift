//
//  BeaconScanner.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 27/11/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import CoreBluetooth

///
/// EddystoneScannerDelegate
///
/// Implement this to receive notifications about beacons discovered in proximity.
public protocol EddystoneScannerDelegate {
    func didFindBeacon(scanner: EddystoneScanner, beacon: Beacon)
    func didLoseBeacon(scanner: EddystoneScanner, beacon: Beacon)
    func didUpdateBeacon(scanner: EddystoneScanner, beacon: Beacon)
}

///
/// EddystoneScanner
///
/// Scans for Eddystone compliant beacons using Core Bluetooth. To receive notifications of any
/// sighted beacons, be sure to implement BeaconScannerDelegate and set that on the scanner.
///
public class EddystoneScanner: NSObject {
    
    public var delegate: EddystoneScannerDelegate?
    
    /// Beacons that are close to the device.
    /// Keeps getting updated. Beacons are removed periodically when no packets are recieved in a 10 second interval
    public var nearbyBeacons = [Beacon]()
    
    
    private var centralManager: CBCentralManager!
    private let beaconOperationsQueue: DispatchQueue = DispatchQueue(label: Constants.BEACON_OPERATION_QUEUE_LABEL)
    private var shouldBeScanning: Bool = false
    
    private var beaconTelemetryCache = [UUID: Data]()
    private var beaconURLCache = [UUID: URL]()
    
    /// Timer to remove beacons not in the the apps proximity
    private var timer: DispatchTimer?
    
    // MARK: Public functions
    /// Initialises the CBCentralManager for scanning and the DispatchTimer
    public override init() {
        super.init()
        
        self.centralManager = CBCentralManager(delegate: self, queue: self.beaconOperationsQueue)
        self.timer = DispatchTimer(repeatingInterval: 10.0, queueLabel: Constants.DISPATCH_TIMER_QUEUE_LABEL)
        self.timer?.delegate = self
    }
    
    ///
    /// Start scanning. If Core Bluetooth isn't ready for us just yet, then waits and THEN starts scanning
    ///
    public func startScanning() {
        self.beaconOperationsQueue.async { [weak self] in
            self?.startScanningSynchronized()
            self?.timer?.startTimer()
        }
    }
    
    ///
    /// Stops scanning for beacons
    ///
    public func stopScanning() {
        self.beaconOperationsQueue.async { [weak self] in
            self?.centralManager.stopScan()
        }
    }
    
    
    // MARK: Private functions
    ///
    /// Starts scanning for beacons
    ///
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
}

extension EddystoneScanner {
    // MARK: Sync functions
    private static func sync(obj: Any, closure: () -> Void) {
        objc_sync_enter(obj)
        closure()
        objc_sync_exit(obj)
    }
    
    private func appendBeacon(beacon: Beacon) {
        EddystoneScanner.sync(obj: self.nearbyBeacons) {
            self.nearbyBeacons.append(beacon)
        }
    }
    
    private func addBeacon(beacon: Beacon, atIndex index: Int) {
        EddystoneScanner.sync(obj: self.nearbyBeacons) {
            self.nearbyBeacons[index] = beacon
        }
    }
}

extension EddystoneScanner: CBCentralManagerDelegate {
    // MARK: CBCentralManagerDelegate callbacks
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && self.shouldBeScanning {
            self.startScanningSynchronized();
        }
    }
    
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
            
            self.delegate?.didUpdateBeacon(scanner: self, beacon: beacon)
            
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
                
                self.delegate?.didFindBeacon(scanner: self, beacon: beacon)
                break
            }
            
            // Beacon already discovered. Update telemetry data
            let beacon = self.nearbyBeacons[index]
            beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
            self.addBeacon(beacon: beacon, atIndex: index)
            
            self.delegate?.didUpdateBeacon(scanner: self, beacon: beacon)
            
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
            
            self.delegate?.didUpdateBeacon(scanner: self, beacon: beacon)
            
        default:
            print("Unable to find service data; can't process Eddystone")
        }
    }
    
}

extension EddystoneScanner: DispatchTimerDelegate {
    // MARK: DispatchTimerProtocol delegate callbackss
    public func timerCalled(timer: DispatchTimer?) {
        EddystoneScanner.sync(obj: self.nearbyBeacons) {
            // Loop through the beacon list and find which beacon has not been seen in the last 15 seconds
            // Mutation of array in-place
            self.nearbyBeacons = self.nearbyBeacons.filter({ (beacon) -> Bool in
                if Date().timeIntervalSince1970 - beacon.lastSeen.timeIntervalSince1970 > 15  {
                    self.delegate?.didLoseBeacon(scanner: self, beacon: beacon)
                    return false
                }
                return true
            })
        }
    }
}

