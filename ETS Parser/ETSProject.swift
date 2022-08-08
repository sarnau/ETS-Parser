//
//  KnxProject.swift
//  KNX_Monitor
//
//  Created by Markus Fritze on 27.09.21.
//

import Foundation
import SWXMLHash
import Zip

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension String {
    func ETSDecodeSerialnumber() -> String {
        let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters)
        let str = (data?.hexEncodedString(options: .upperCase))!
        return str.prefix(4) + ":" + str[str.index(str.startIndex, offsetBy: 4)...]
    }
}

func ETSPhysicalAddress(area_address: Int?, line_address: Int?, device_address: Int?) -> String {
    if let area_address = area_address, let line_address = line_address, let device_address = device_address {
        return "\(area_address).\(line_address).\(device_address)"
    }
    if let area_address = area_address, let line_address = line_address {
        return "\(area_address).\(line_address)"
    }
    if let area_address = area_address {
        return "\(area_address)"
    }
    return "?"
}

func ETSGroupAddress(knxProject: ETSProject, address: Int?) -> String {
    if let address = address {
        switch knxProject.groupAddressStyle {
        case .ThreeLevel: return String(format: "%d/%d/%d", address >> (3 + 8), (address >> 8) & 0x7, address & 0xFF)
        case .TwoLevel: return String(format: "%d/%d", address >> (3 + 8), address & 0x7FF)
        case .Free: return String(format: "%d", address)
        }
    }
    return "?"
}

func ETSProjectUrl(url: URL) -> URL {
    let directoryName = url.deletingPathExtension().lastPathComponent
    let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return documentsUrl.appendingPathComponent(directoryName, isDirectory: true)
}

func ETSDecompressProject(url: URL, password: String?) throws {
    Zip.addCustomFileExtension(url.pathExtension)
    let knxProjectUrl = ETSProjectUrl(url: url)
    if FileManager.default.fileExists(atPath: knxProjectUrl.path) == false {
        try Zip.unzipFile(url, destination: knxProjectUrl, overwrite: true, password: nil, progress: nil)
    }
    let fileManager = FileManager.default
    if let enumerator = fileManager.enumerator(at: knxProjectUrl, includingPropertiesForKeys: nil) {
        while let fileObj = enumerator.nextObject() {
            if fileObj is URL {
                let suburl = (fileObj as! URL)
                // remove files, which we co not need
                if suburl.pathExtension == "signature" {
                    try fileManager.removeItem(at: suburl)
                } else if suburl.pathExtension == "certificate" {
                    try fileManager.removeItem(at: suburl)
                } else if suburl.lastPathComponent == ".DS_Store" {
                    try fileManager.removeItem(at: suburl)
                } else if suburl.lastPathComponent == "Catalog.xml" {
                    try fileManager.removeItem(at: suburl)
                } else if suburl.lastPathComponent == "Baggages.xml" {
                    try fileManager.removeItem(at: suburl)
                } else if suburl.path.contains("Baggages") {
                    try fileManager.removeItem(at: suburl)
                } else if suburl.pathExtension == "zip" {
                    try Zip.unzipFile(suburl, destination: suburl.deletingPathExtension(), overwrite: true, password: password, progress: nil)
                    try fileManager.removeItem(at: suburl) // done with the ZIP
                }
            }
        }
    }
}

func ETSLoadMaster(url: URL) throws -> ETSMasterData_t {
    var knxJsonUrl = ETSProjectUrl(url: url)
    knxJsonUrl.appendPathComponent("knx_master.json")
    do {
        let jsonData = try Data(contentsOf: knxJsonUrl)
        return try JSONDecoder().decode(ETSMasterData_t.self, from: jsonData)
    } catch {
    }
    var knxMaster = ETSMasterData_t(datapoints: [:], mediumTypes: [:], manufacturers: [:], spaceUsage: [:], products: [:], hardware2Programs: [:])

    // parse knx_master
    knxMaster.datapoints = [:]
    let knxProjectUrl = ETSProjectUrl(url: url)
    let knx_master_Url = knxProjectUrl.appendingPathComponent("knx_master.xml")
    let xml = SWXMLHash.config {
        config in
        config.shouldProcessLazily = true
    }.parse(try String(contentsOf: knx_master_Url, encoding: .utf8))
    for datapointType in xml["KNX"]["MasterData"]["DatapointTypes"]["DatapointType"].all {
        let id = try datapointType.value(ofAttribute: "Id") as ID
        let number = try datapointType.value(ofAttribute: "Number") as Int
        let name = try datapointType.value(ofAttribute: "Name") as String255_t
        let text = try datapointType.value(ofAttribute: "Text") as LanguageDependentString255_t
        knxMaster.datapoints[id] = ETSDatapointType(number: "\(number)", name: name, text: text)
        for datapointSubtype in datapointType["DatapointSubtypes"]["DatapointSubtype"].all {
            let id = try datapointSubtype.value(ofAttribute: "Id") as ID
            let snumber = try datapointSubtype.value(ofAttribute: "Number") as Int
            let name = try datapointSubtype.value(ofAttribute: "Name") as String255_t
            let text = try datapointSubtype.value(ofAttribute: "Text") as LanguageDependentString255_t
            let formattedValue = String(format: "%03d", snumber)
            knxMaster.datapoints[id] = ETSDatapointType(number: "\(number).\(formattedValue)", name: name, text: text)
        }
    }
    for mediumType in xml["KNX"]["MasterData"]["MediumTypes"]["MediumType"].all {
        let id = try mediumType.value(ofAttribute: "Id") as ID
        let number = try mediumType.value(ofAttribute: "Number") as Int
        let name = try mediumType.value(ofAttribute: "Name") as String20_t
        let text = try mediumType.value(ofAttribute: "Text") as LanguageDependentString50_t
        knxMaster.mediumTypes[id] = ETSMediumType(number: number, name: name, text: text)
    }
    for space in xml["KNX"]["MasterData"]["SpaceUsages"]["SpaceUsage"].all {
        let id = try space.value(ofAttribute: "Id") as ID
        let number = try space.value(ofAttribute: "Number") as Int
        let text = try space.value(ofAttribute: "Text") as String255_t
        knxMaster.spaceUsage[id] = ETSSpaceUsage(number: number, text: text)
    }
    for space in xml["KNX"]["MasterData"]["Manufacturers"]["Manufacturer"].all {
        let id = try space.value(ofAttribute: "Id") as ID
        let knxManufacturerId = try space.value(ofAttribute: "KnxManufacturerId") as Int
        let name = try space.value(ofAttribute: "Name") as String255_t
        knxMaster.manufacturers[id] = ETSManufacturer(knxManufacturerId: knxManufacturerId, name: name)
    }

    // parse other KNX manufacturer XML files
    if let enumerator = FileManager.default.enumerator(at: knxProjectUrl, includingPropertiesForKeys: nil) {
        while let fileObj = enumerator.nextObject() {
            if fileObj is URL {
                let suburl = (fileObj as! URL)
                if suburl.isDirectory {
                    continue
                }
                if suburl.lastPathComponent == "Hardware.xml" {
                    let xml = SWXMLHash.config {
                        config in
                        config.shouldProcessLazily = true
                    }.parse(try String(contentsOf: suburl, encoding: .utf8))
                    for manufacturer in xml["KNX"]["ManufacturerData"]["Manufacturer"].all {
                        let manufacturerPathPrefix = try manufacturer.value(ofAttribute: "RefId") as IDREF
                        for hardware in manufacturer["Hardware"]["Hardware"].all {
                            for product in hardware["Products"]["Product"].all {
                                let id = try product.value(ofAttribute: "Id") as ID
                                let text = try product.value(ofAttribute: "Text") as LanguageDependentString255_t
                                let orderNumber = try product.value(ofAttribute: "OrderNumber") as String50_t
                                knxMaster.products[id] = ETSProduct(text: text, orderNumber: orderNumber, manufacturer: knxMaster.manufacturers[manufacturerPathPrefix]!)
                            }
                            for hardware2Program in hardware["Hardware2Programs"]["Hardware2Program"].all {
                                let id = try hardware2Program.value(ofAttribute: "Id") as ID
                                var mediumTypes: [ETSMediumType] = []
                                if let mediumTypesIds = hardware2Program.value(ofAttribute: "MediumTypes") as IDREFS? {
                                    for mediumTypeId in (mediumTypesIds.split(separator: " ").map { IDREF($0) }) {
                                        mediumTypes.append(knxMaster.mediumTypes[mediumTypeId]!)
                                    }
                                }
                                let applicationProgramRef = try hardware2Program["ApplicationProgramRef"].value(ofAttribute: "RefId") as IDREF
                                let applicationProgramXml = knxProjectUrl.appendingPathComponent(manufacturerPathPrefix).appendingPathComponent(applicationProgramRef).appendingPathExtension("xml")
                                let xml = SWXMLHash.config {
                                    config in
                                    config.shouldProcessLazily = true
                                }.parse(try String(contentsOf: applicationProgramXml, encoding: .utf8))
                                var comObjectsRefs: [String: ETSComObjectInstanceRef_t] = [:]
                                for applicationProgram in xml["KNX"]["ManufacturerData"]["Manufacturer"]["ApplicationPrograms"]["ApplicationProgram"].all {
//                                    let id = try applicationProgram.value(ofAttribute: "Id") as String
//                                    let name = try applicationProgram.value(ofAttribute: "Name") as String
//                                    let applicationNumber = try applicationProgram.value(ofAttribute: "ApplicationNumber") as String
//                                    let applicationVersion = try applicationProgram.value(ofAttribute: "ApplicationVersion") as String
//                                    let maskVersion = try applicationProgram.value(ofAttribute: "MaskVersion") as String
//                                    print("\(id) : \(name) - \(applicationNumber) - \(applicationVersion) - \(maskVersion)")
                                    func setupComObjectInstance(comObject: ETSComObjectInstanceRef_t, xml: XMLIndexer) -> ETSComObjectInstanceRef_t {
                                        var comObject = comObject
                                        comObject.Number = xml.value(ofAttribute: "Number") as Int?
                                        comObject.Text = xml.value(ofAttribute: "Text") as LanguageDependentString255_t?
                                        comObject.FunctionText = xml.value(ofAttribute: "FunctionText") as LanguageDependentString255_t?
                                        if let objectSize = xml.value(ofAttribute: "ObjectSize") as String? {
                                            comObject.ObjectSize = ETSComObjectSize_t(rawValue: objectSize)
                                        }
                                        if let flag = xml.value(ofAttribute: "ReadFlag") as String? {
                                            comObject.ReadFlag = ETSEnable_t(rawValue: flag) == .Enabled
                                        }
                                        if let flag = xml.value(ofAttribute: "WriteFlag") as String? {
                                            comObject.WriteFlag = ETSEnable_t(rawValue: flag) == .Enabled
                                        }
                                        if let flag = xml.value(ofAttribute: "CommunicationFlag") as String? {
                                            comObject.CommunicationFlag = ETSEnable_t(rawValue: flag) == .Enabled
                                        }
                                        if let flag = xml.value(ofAttribute: "TransmitFlag") as String? {
                                            comObject.TransmitFlag = ETSEnable_t(rawValue: flag) == .Enabled
                                        }
                                        if let flag = xml.value(ofAttribute: "UpdateFlag") as String? {
                                            comObject.UpdateFlag = ETSEnable_t(rawValue: flag) == .Enabled
                                        }
                                        if let flag = xml.value(ofAttribute: "ReadOnInitFlag") as String? {
                                            comObject.ReadOnInitFlag = ETSEnable_t(rawValue: flag) == .Enabled
                                        }
                                        if let idrefs = xml.value(ofAttribute: "DatapointType") as IDREFS? {
                                            comObject.datapointType = []
                                            for idref in (idrefs.split(separator: " ").map { IDREF($0) }) {
                                                if let dp = knxMaster.datapoints[idref] {
                                                    comObject.datapointType!.append(dp)
                                                }
                                            }
                                        }
                                        return comObject
                                    }
                                    var comObjectsTable: [String: ETSComObjectInstanceRef_t] = [:]
                                    for comObject in applicationProgram["Static"]["ComObjectTable"]["ComObject"].all {
                                        let id = try comObject.value(ofAttribute: "Id") as ID
                                        comObjectsTable[id] = setupComObjectInstance(comObject: ETSComObjectInstanceRef_t(), xml: comObject)
                                    }
                                    for comObjectRef in applicationProgram["Static"]["ComObjectRefs"]["ComObjectRef"].all {
                                        let id = try comObjectRef.value(ofAttribute: "Id") as ID
                                        let refId = try comObjectRef.value(ofAttribute: "RefId") as IDREF
                                        comObjectsRefs[id] = setupComObjectInstance(comObject: comObjectsTable[refId] ?? ETSComObjectInstanceRef_t(), xml: comObjectRef)
                                    }
                                }
                                knxMaster.hardware2Programs[id] = ETSHardware2Program_t(mediumTypes: mediumTypes, comObjects: comObjectsRefs)
                            }
                        }
                    }
                }
            }
        }
    }
    let data = try JSONEncoder().encode(knxMaster)
    try data.write(to: knxJsonUrl)
    return knxMaster
}

func ETSLoadProject(knxMaster: ETSMasterData_t, url: URL) throws -> ETSProject {
//    var knxJsonUrl = knxProjectUrl(url: url)
//    knxJsonUrl.appendPathComponent("project.json")
//    do {
//        let jsonData = try Data(contentsOf: knxJsonUrl)
//        return try JSONDecoder().decode(KnxProject.self, from: jsonData)
//    } catch {
//    }
    var knxProject = ETSProject(id: "", name: "???", groupAddressStyle: .ThreeLevel, topology: [:], locations: [:], groupAddresses: [:])

    // parse the project file
    let knxProjectUrl = ETSProjectUrl(url: url)
    var projectI = "0"
    if let enumerator = FileManager.default.enumerator(at: knxProjectUrl, includingPropertiesForKeys: nil) {
        while let fileObj = enumerator.nextObject() {
            if fileObj is URL {
                let suburl = (fileObj as! URL)
                if suburl.isDirectory {
                    continue
                }
                let subpath = suburl.path.deletingPrefix(knxProjectUrl.path)
                if subpath.hasPrefix("/P-") {
                    if suburl.lastPathComponent == "project.xml" {
                        let xml = SWXMLHash.parse(try String(contentsOf: suburl, encoding: .utf8))
                        let project = xml["KNX"]["Project"]
                        knxProject.id = try project.value(ofAttribute: "Id")
                        for projectInformation in project["ProjectInformation"].all {
                            knxProject.name = projectInformation.value(ofAttribute: "Name") as String50_t?
                            knxProject.groupAddressStyle = ETSGroupAddressStyle_t(rawValue: (projectInformation.value(ofAttribute: "GroupAddressStyle") as String?)!)!
                        }
                    } else {
                        projectI = suburl.deletingPathExtension().lastPathComponent
                    }
                }
            }
        }
    }

    /// strip local knx project file ID prefix
    func deleteIdPrefix(_ id: IDREF) -> RELIDREF {
        return id.deletingPrefix(knxProject.id + "-" + String(projectI) + "_")
    }

    // read the installation data
    let installationDataUrl = knxProjectUrl.appendingPathComponent(knxProject.id).appendingPathComponent(String(projectI)).appendingPathExtension("xml")
    let xml = SWXMLHash.parse(try String(contentsOf: installationDataUrl, encoding: .utf8))
    for area in xml["KNX"]["Project"]["Installations"]["Installation"]["Topology"]["Area"].all {
        let id = deleteIdPrefix(try area.value(ofAttribute: "Id") as ID)
        let area_address = area.value(ofAttribute: "Address") as Int?
        let name = area.value(ofAttribute: "Name") as String255_t?
        var lines: [String: ETSTopology_t_Area_Line] = [:]
        for line in area["Line"].all {
            let id = deleteIdPrefix(try line.value(ofAttribute: "Id") as ID)
            let line_address = line.value(ofAttribute: "Address") as Int?
            let name = line.value(ofAttribute: "Name") as String255_t?
            let mediumType = knxMaster.mediumTypes[(line.value(ofAttribute: "MediumTypeRefId") as IDREF?)!]
            var devices: [String: ETSDeviceInstance_t] = [:]
            for device in line["DeviceInstance"].all {
                let id = deleteIdPrefix(try device.value(ofAttribute: "Id") as ID)
                let device_address = device.value(ofAttribute: "Address") as Int?
                let name = device.value(ofAttribute: "Name") as String255_t?
                let productRefId = device.value(ofAttribute: "ProductRefId") as IDREF?
                let hardware2ProgramRefId = device.value(ofAttribute: "Hardware2ProgramRefId") as IDREF?
                let comment = device.value(ofAttribute: "Comment") as String?
                let description = device.value(ofAttribute: "Description") as String?
                let serialNumber = (device.value(ofAttribute: "SerialNumber") as String?)?.ETSDecodeSerialnumber()
                var deviceLinks: [String: [String?]] = [:]
                for device in device["ComObjectInstanceRefs"]["ComObjectInstanceRef"].all {
                    if let refId = device.value(ofAttribute: "RefId") as RELIDREF? {
                        if let links = device.value(ofAttribute: "Links") as RELIDREFS? {
                            deviceLinks[refId] = links.split(separator: " ").map { RELIDREF($0) }
                        }
                    }
                }
                devices[id] = ETSDeviceInstance_t(physAddress: ETSPhysicalAddress(area_address: area_address, line_address: line_address, device_address: device_address), name: name, productRefId: productRefId, hardware2ProgramRefId: hardware2ProgramRefId, comment: comment, description: description, serialNumber: serialNumber, links: deviceLinks)
            }
            lines[id] = ETSTopology_t_Area_Line(physAddress: ETSPhysicalAddress(area_address: area_address, line_address: line_address, device_address: nil), name: name, mediumType: mediumType, devices: devices)
        }
        knxProject.topology[id] = ETSTopology_t_Area(physAddress: ETSPhysicalAddress(area_address: area_address, line_address: nil, device_address: nil), name: name, lines: lines)
    }

    for groupAddresses in xml["KNX"]["Project"]["Installations"]["Installation"]["GroupAddresses"].all {
        func enumerate(indexer: XMLIndexer) throws {
            for child in indexer.children {
                let element = child.element!
                if element.name == "GroupAddress" {
                    var id = try element.value(ofAttribute: "Id") as RELIDREF
                    id = id.deletingPrefix(knxProject.id + "-" + String(projectI) + "_")
                    let address = element.value(ofAttribute: "Address") as Int?
                    let name = element.value(ofAttribute: "Name") as String255_t?
                    var dp: ETSDatapointType?
                    if let dpStr = element.value(ofAttribute: "DatapointType") as IDREF? {
                        dp = knxMaster.datapoints[dpStr]
                    }
                    knxProject.groupAddresses[id] = ETSGroupAddresses_t(groupAddress: ETSGroupAddress(knxProject: knxProject, address: address), name: name, datapointType: dp)
                }
                try enumerate(indexer: child)
            }
        }
        try enumerate(indexer: groupAddresses)
    }

    for child in xml["KNX"]["Project"]["Installations"]["Installation"]["Locations"]["Space"].all {
        func createSpace(child: XMLIndexer) throws -> ETSSpace_t {
            let element = child.element!
            let type = ETSBuildingPartType_t(rawValue: (element.value(ofAttribute: "Type") as String?)!)
            let name = element.value(ofAttribute: "Name") as String255_t?
            let number = element.value(ofAttribute: "Number") as String255_t?
            let description = element.value(ofAttribute: "Description") as String?
            var usage: ETSSpaceUsage?
            if let spaceName = element.value(ofAttribute: "Usage") as IDREF? {
                usage = knxMaster.spaceUsage[spaceName]
            }
            return ETSSpace_t(name: name, number: number, type: type, usage: usage, description: description, spaces: nil, devices: nil)
        }
        var id = try child.value(ofAttribute: "Id") as RELIDREF
        id = id.deletingPrefix(knxProject.id + "-" + String(projectI) + "_")
        func enumerate(indexer: XMLIndexer, space: ETSSpace_t) throws -> ETSSpace_t {
            var space = space
            var spaces: [String: ETSSpace_t] = [:]
            var devices: [String] = []
            for child in indexer.children {
                let element = child.element!
                if element.name == "Space" {
                    var id = try element.value(ofAttribute: "Id") as RELIDREF
                    id = id.deletingPrefix(knxProject.id + "-" + String(projectI) + "_")
                    spaces[id] = try enumerate(indexer: child, space: try createSpace(child: child))
                } else if element.name == "DeviceInstanceRef" {
                    var refId = try element.value(ofAttribute: "RefId") as RELIDREF
                    refId = refId.deletingPrefix(knxProject.id + "-" + String(projectI) + "_")
                    devices.append(refId)
                }
            }
            space.spaces = spaces
            space.devices = devices
            return space
        }
        knxProject.locations[id] = try enumerate(indexer: child, space: try createSpace(child: child))
    }

//    let data = try JSONEncoder().encode(knxProject)
//    try data.write(to: knxJsonUrl)
    return knxProject
}

func ETSLoadProject(url: URL, password: String?) throws -> ETSProject {
    try ETSDecompressProject(url: url, password: password)
    let knxMaster = try ETSLoadMaster(url: url)
    return try ETSLoadProject(knxMaster: knxMaster, url: url)
}
