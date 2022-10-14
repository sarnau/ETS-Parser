//
//  ETSTypes.swift
//  ETS Parser
//
//  Created by Markus Fritze on 27.09.21.
//

import Foundation

/// Unique ID
typealias ID = String
/// This type is used for references to xs:ID. In contrast to the standard XML IDREF type, the referenced element need not be in the same XML file.
typealias IDREF = String
/// This type is used for multiple references to xs:ID, separated by space. In contrast to the standard XML IDREFS type, the referenced elements need not be in the same XML file.
typealias IDREFS = String
/// This type is used for references to elements below a known application program, e.g. instead of the IDREF "M-0004_A-104E-01-5221-O000A_O-2_R-199", the RELIDREF is shortened to " O-2_R-199".
typealias RELIDREF = String
/// This type is used for multiple references to knx:RELIDREF, separated by space.
typealias RELIDREFS = String
/// Same as xs:string, but restricted to 20 unicode characters.
typealias String20_t = String
/// Same as xs:string, but restricted to 50 unicode characters.
typealias String50_t = String
/// Same as xs:string, but restricted to 255 unicode characters.
typealias String255_t = String
/// This type is for specifying the name of ModuleDef\Arguments\Argument.
typealias Identifier50_t = String
/// This type is used for texts in master or product data that may be translated to different languages.
typealias LanguageDependentString_t = String
/// Same as LanguageDependentString_t, but restricted to 50 unicode characters.
typealias LanguageDependentString50_t = String
/// Same as LanguageDependentString_t, but restricted to 255 unicode characters.
typealias LanguageDependentString255_t = String
/// This type is for specifying IP v4 addresses, e.g. the IP routing multicast address. ((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])
typealias Ipv4Address_t = String
/// This type is for specifying registration numbers in the format yyyy/n
typealias RegistrationNumber_t = String
/// This type is for specifying the VersionNumber of a hardware. Restricted to ensure compatibility with ETS3
typealias HardwareVersionNumber_t = CUnsignedShort

//-----------------------------------------------------------------------------------

/// This enumeration encodes the rights for the ETS user to view and modify parameters.
enum ETSAccess_t: String, Codable {
    case None,Read,ReadWrite
}

/// This enumeration contains the different types of representations of group addresses in ETS4. 2-level and 3-level style are also available in ETS3, the free group address structure is new to ETS4.
enum ETSGroupAddressStyle_t: String, Codable {
    case ThreeLevel, TwoLevel, Free
}

/// This enumeration contains the different types of available spaces in the ETS5.
enum ETSBuildingPartType_t: String, Codable {
    case Building, BuildingPart, Floor, Stairway, Room, Corridor, DistributionBoard, Area, Ground, Segment
}

/// This enumeration lists the possible transmission priorities available in the KNX protocol.
enum ETSComObjectPriority_t: String, Codable {
    case Low,High,Alert
}

/// This enumeration lists the possible data sizes for KNX group communication.
enum ETSComObjectSize_t: String, Codable {
case Size1Bit = "1 Bit",
    Size2Bit = "2 Bit",
    Size3Bit = "3 Bit",
    Size4Bit = "4 Bit",
    Size5Bit = "5 Bit",
    Size6Bit = "6 Bit",
    Size7Bit = "7 Bit",
    Size1Byte = "1 Byte",
    Size2Bytes = "2 Bytes",
    Size3Bytes = "3 Bytes",
    Size4Bytes = "4 Bytes",
    Size5Bytes = "5 Bytes",
    Size6Bytes = "6 Bytes",
    Size7Bytes = "7 Bytes",
    Size8Bytes = "8 Bytes",
    Size9Bytes = "9 Bytes",
    Size10Bytes = "10 Bytes",
    Size11Bytes = "11 Bytes",
    Size12Bytes = "12 Bytes",
    Size13Bytes = "13 Bytes",
    Size14Bytes = "14 Bytes",
    Size15Bytes = "15 Bytes",
    Size16Bytes = "16 Bytes",
    Size17Bytes = "17 Bytes",
    Size18Bytes = "18 Bytes",
    Size19Bytes = "19 Bytes",
    Size20Bytes = "20 Bytes",
    Size21Bytes = "21 Bytes",
    Size22Bytes = "22 Bytes",
    Size23Bytes = "23 Bytes",
    Size24Bytes = "24 Bytes",
    Size25Bytes = "25 Bytes",
    Size26Bytes = "26 Bytes",
    Size27Bytes = "27 Bytes",
    Size28Bytes = "28 Bytes",
    Size29Bytes = "29 Bytes",
    Size30Bytes = "30 Bytes",
    Size31Bytes = "31 Bytes",
    Size32Bytes = "32 Bytes",
    Size33Bytes = "33 Bytes",
    Size34Bytes = "34 Bytes",
    Size35Bytes = "35 Bytes",
    Size36Bytes = "36 Bytes",
    Size37Bytes = "37 Bytes",
    Size38Bytes = "38 Bytes",
    Size39Bytes = "39 Bytes",
    Size40Bytes = "40 Bytes",
    Size41Bytes = "41 Bytes",
    Size42Bytes = "42 Bytes",
    Size43Bytes = "43 Bytes",
    Size44Bytes = "44 Bytes",
    Size45Bytes = "45 Bytes",
    Size46Bytes = "46 Bytes",
    Size47Bytes = "47 Bytes",
    Size48Bytes = "48 Bytes",
    Size49Bytes = "49 Bytes",
    Size50Bytes = "50 Bytes",
    SizeLegacyVarData = "LegacyVarData"
}

/// ToDo status enumeration:
enum ETSToDoStatus_t: String, Codable {
    case Open,Accomplished
}

/// Several elements contain a completion status attrubute which might have one of the following values:
enum ETSCompletionStatus_t: String, Codable {
    case Undefined,Editing,FinishedDesign,FinishedCommissioning,Tested,Accepted,Locked
}

/// This enumeration is used for the group object communication flags.:
enum ETSEnable_t: String, Codable {
    case Enabled,Disabled
}

/// This enum represents the different options for secure communication
enum ETSSecurityMode_t: String, Codable {
    case Auto,On,Off
}

//-----------------------------------------------------------------------------------

// global information, which are not part of the project itself – read-only
struct ETSMasterData_t: Codable {
    var datapoints: [String: ETSDatapointType]
    var mediumTypes: [IDREF: ETSMediumType]
    var manufacturers: [String: ETSManufacturer]
    var spaceUsage: [String: ETSSpaceUsage]
    var products: [String: ETSProduct]
    var hardware2Programs: [String: ETSHardware2Program_t]
}

// a single datapoint
struct ETSDatapointType: Codable {
    var number: String // Main datapoint number
    var name: String255_t // Official name of the datapoint main type
    var text: LanguageDependentString255_t // Name for display to the user
}

/// Medium Types, like Twisted Pair or KNXnet/IP
struct ETSMediumType: Codable {
    var number: Int // Medium type number
    var name: String20_t // Official name, e.g. "TP", "PL", "RF", “IP”
    var text: LanguageDependentString50_t // Longer Name for display to the user
}

/// Info about a manufacturer
struct ETSManufacturer: Codable {
    var knxManufacturerId: Int // On export or conversion, this will be constructed as M-nnnn, where:nnnn KnxManufacturerId, formatted as 4 hexadecimal digits.
    var name: String255_t // Manufacturer name
}

// Spaces (rooms, etc)
struct ETSSpaceUsage: Codable {
    var number: Int
    var text: LanguageDependentString255_t
}

/// Info about a specific hardware product
struct ETSProduct: Codable {
    var text: String // Name of the product as displayed to the user.
    var orderNumber: String50_t // Order number; must be unique within all products of one manufacturer
    var manufacturer: ETSManufacturer
}

struct ETSComObjectInstanceRef_t: Codable {
    var Number: Int?
    var Text: LanguageDependentString255_t? // Visible communication object name. If missing, the attribute of the underlying ComObjectRef or ComObject is used
    var FunctionText: LanguageDependentString255_t? // Visible communication object function name. If missing, the attribute of the underlying ComObjectRef or ComObject is used
    var ObjectSize: ETSComObjectSize_t?
    var ReadFlag: Bool? // Read flag. If missing, the attribute of the underlying ComObjectRef or ComObject is used.
    var WriteFlag: Bool? // Write flag. If missing, the attribute of the underlying ComObjectRef or ComObject is used.
    var CommunicationFlag: Bool? // Communication flag. If missing, the attribute of the underlying ComObjectRef or ComObject is used.
    var TransmitFlag: Bool? // Transmit flag. If missing, the attribute of the underlying ComObjectRef or ComObject is used.
    var UpdateFlag: Bool? // Update flag. If missing, the attribute of the underlying ComObjectRef or ComObject is used.
    var ReadOnInitFlag: Bool? // ReadOnInit flag. If missing, the attribute of the underlying ComObjectRef or ComObject is used.

    var datapointType: [ETSDatapointType]?
}

/// Translates a hardware to an application XML
struct ETSHardware2Program_t: Codable {
    var mediumTypes: [ETSMediumType] // Reference to one or more MediumTypes
    var comObjects: [ID: ETSComObjectInstanceRef_t]
}

//-----------------------------------------------------------------------------------

// the actual project
struct ETSProject: Codable {
    var id: ID   // Unique ID of the project in the knxproj container. On export or conversion, this will be constructed as P-nnnn, where: nnnn Random 16Bit Identifier, formatted as 4 hexadecimal digits . Must be unique in the knxproj container.
    var name: String50_t? // Project Name
    var groupAddressStyle: ETSGroupAddressStyle_t // Representation of group addresses in this project

    var topology: [ID: ETSTopology_t_Area]
    var locations: [ID: ETSSpace_t]
    var groupAddresses: [ID: ETSGroupAddresses_t]
}

// a specific device instance
struct ETSDeviceInstance_t: Codable {
    var physAddress: String? // Device address [0...255]
    var name: String255_t? // Device name
    var productRefId: String? // Reference to a Product; must be a child of the Hardware2Progrem element
    var hardware2ProgramRefId: String? // Reference to a Hardware2Program
    var comment: String? // Device comment
    var description: String? // Device description.
    var serialNumber: String? // The SerialNumber is used for DownloadIndividualAddressBySerialNumber. This serial number must be provided base64 encoded.

    var links: [ID: [String?]]
}

// a KNX line contains devices
struct ETSTopology_t_Area_Line: Codable {
    var physAddress: String? // Line address [0...15]
    var name: String255_t? // Name of the line
    var mediumType: ETSMediumType? // Medium type of the line, a reference to MediumType.
    var devices: [ID: ETSDeviceInstance_t]
}

// a KNX area contains lines
struct ETSTopology_t_Area: Codable {
    var physAddress: String? // Area address [0...15]
    var name: String255_t? // Name of the area
    var lines: [ID: ETSTopology_t_Area_Line]
}

struct ETSSpace_t: Codable {
    var name: String255_t? // Name
    var number: String255_t? // Optional number
    var type: ETSBuildingPartType_t? // One of: "Building", "BuildingPart", "Floor", "Room", "RoomPart", "DistributionBoard", “Stairway”, “Corridor”, “Area”, “Ground” and “Segment”.
    var usage: ETSSpaceUsage? // The optional usage for this space.
    var description: String? // Description

    var spaces: [ID:ETSSpace_t]?
    var devices: [String]?
}

// a KNX group address types datapoints together
struct ETSGroupAddresses_t: Codable {
    var groupAddress: String // Group address [1...65535]
    var name: String255_t? // Name
    var datapointType: ETSDatapointType?
}
