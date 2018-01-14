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
public protocol ScannerDelegate {
    func didFindBeacon(scanner: Scanner, beacon: Beacon)
    func didLoseBeacon(scanner: Scanner, beacon: Beacon)
    func didUpdateBeacon(scanner: Scanner, beacon: Beacon)
}

///
/// EddystoneScanner
///
/// Scans for Eddystone compliant beacons using Core Bluetooth. To receive notifications of any
/// sighted beacons, be sure to implement BeaconScannerDelegate and set that on the scanner.
///
public class Scanner: NSObject {
    
    /// Scanner Delegate
    public var delegate: ScannerDelegate?
    
    /// Beacons that are close to the device.
    /// Keeps getting updated. Beacons are removed periodically when no packets are recieved in a 10 second interval
    public var nearbyBeacons = SafeSet<Beacon>(identifier: "nearbyBeacons")
    
    
    private var centralManager: CBCentralManager!
    private let beaconOperationsQueue: DispatchQueue = DispatchQueue(label: Constants.BEACON_OPERATION_QUEUE_LABEL)
    private var shouldBeScanning: Bool = false
    
    private var beaconTelemetryCache = SafeDictionary<UUID, Data>(identifier: "beaconTelemetryCache")
    private var beaconURLCache = SafeDictionary<UUID, URL>(identifier: "beaconURLCache")
    
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
            debugPrint("CentralManager state is %d, cannot start scan", self.centralManager.state.rawValue)
            self.shouldBeScanning = true
        }
        else {
            debugPrint("Starting to scan for Eddystones")
            let services = [CBUUID(string: "FEAA")]
            let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
            self.centralManager.scanForPeripherals(withServices: services, options: options)
        }
    }
}

extension Scanner: CBCentralManagerDelegate {
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
        
        let frameType = Eddystone.frameTypeForFrame(advertisementFrameList: serviceData)
        switch frameType {
        case .telemetry:
            self.handleTelemetryFrame(peripheral: peripheral, serviceData: serviceData, RSSI: RSSI)
            
        case .uid, .eid:
            self.handleEIDUIDFrame(peripheral: peripheral, serviceData: serviceData, RSSI: RSSI)
            
        case .url:
            self.handleURLFrame(peripheral: peripheral, serviceData: serviceData, RSSI: RSSI)
            
        default:
            debugPrint("Unable to find service data; can't process Eddystone")
        }
    }
    
    // MARK: CBCentralManagerDelegate helper methods
    /// Handle telemetry frame data
    private func handleTelemetryFrame(peripheral: CBPeripheral,
                                     serviceData: [NSObject: AnyObject],
                                     RSSI: NSNumber) {
        let telemetryData = Eddystone.telemetryDataForFrame(advertisementFrameList: serviceData)
        let eddystoneURL = self.beaconURLCache[peripheral.identifier]
        
        // Stash away the telemetry data for later use
        beaconTelemetryCache[peripheral.identifier] = telemetryData
        
        guard let index = nearbyBeacons.index(where: {$0.identifier == peripheral.identifier}) else {
            return
        }
        
        // Save the changing beacon data into the beacon object
        let beacon = self.nearbyBeacons[index]
        beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
        self.nearbyBeacons.update(with: beacon)
        
        self.delegate?.didUpdateBeacon(scanner: self, beacon: beacon)
    }
    
    /// Handle EID UID frame
    private func handleEIDUIDFrame(peripheral: CBPeripheral,
                                      serviceData: [NSObject: AnyObject],
                                      RSSI: NSNumber) {
        let telemetryData = self.beaconTelemetryCache[peripheral.identifier]
        let eddystoneURL = self.beaconURLCache[peripheral.identifier]
        
        guard let index = nearbyBeacons.index(where: {$0.identifier == peripheral.identifier}) else {
            // Newly discovered beacon. Create a new beacon object
            let beaconServiceData = serviceData[Eddystone.ServiceUUID] as? Data
            guard let beacon = Beacon(identifier: peripheral.identifier,
                                      frameData: beaconServiceData,
                                      rssi: RSSI.intValue) else {
                                        return
            }
            
            beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
            self.nearbyBeacons.insert(beacon)
            
            self.delegate?.didFindBeacon(scanner: self, beacon: beacon)
            return
        }
        
        // Beacon already discovered. Update telemetry data
        let beacon = self.nearbyBeacons[index]
        beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
        self.nearbyBeacons.update(with: beacon)
        
        self.delegate?.didUpdateBeacon(scanner: self, beacon: beacon)
    }
    
    /// Handle URL frame
    private func handleURLFrame(peripheral: CBPeripheral,
                                   serviceData: [NSObject: AnyObject],
                                   RSSI: NSNumber) {
        let telemetryData = self.beaconTelemetryCache[peripheral.identifier]
        let eddystoneURL = Eddystone.parseURLFromFrame(advertisementFrameList: serviceData)
        
        // Stash away the URL for later use
        self.beaconURLCache[peripheral.identifier] = eddystoneURL
        
        guard let index = nearbyBeacons.index(where: {$0.identifier == peripheral.identifier}) else {
            return
        }
        
        // Update the beacon object
        let beacon = self.nearbyBeacons[index]
        beacon.updateBeacon(telemetryData: telemetryData, eddystoneURL: eddystoneURL, rssi: RSSI.intValue)
        self.nearbyBeacons.update(with: beacon)
        
        self.delegate?.didUpdateBeacon(scanner: self, beacon: beacon)
    }
    
}

extension Scanner: DispatchTimerDelegate {
    // MARK: DispatchTimerProtocol delegate callbacks
    public func timerCalled(timer: DispatchTimer?) {
        // Loop through the beacon list and find which beacon has not been seen in the last 15 seconds
        self.nearbyBeacons.filterInPlace() { beacon in
            if Date().timeIntervalSince1970 - beacon.lastSeen.timeIntervalSince1970 > 15  {
                self.delegate?.didLoseBeacon(scanner: self, beacon: beacon)
                return false
            }
            return true
        }
    }
}

