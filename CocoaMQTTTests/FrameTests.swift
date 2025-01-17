//
//  FrameTests.swift
//  CocoaMQTT
//
//  Created by HJianBo on 2018/12/31.
//  Copyright © 2018 emqx.io. All rights reserved.
//

import XCTest
@testable import CocoaMQTT

class FrameTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFrameConnect() {
        var conn = FrameConnect(clientID: "sheep")
        conn.keepalive = 60
        conn.cleansess = true
        
        XCTAssertEqual(conn.fixedHeader, 0x10)
        XCTAssertEqual(conn.type, FrameType.connect)
        XCTAssertEqual(conn.dup, false)
        XCTAssertEqual(conn.qos, .qos0)
        XCTAssertEqual(conn.retained, false)
        
        XCTAssertEqual(conn.bytes(),
                       [0x10, 0x11,
                        0x00, 0x04, 0x4D, 0x51, 0x54, 0x54,         // MQTT
                        0x04,                                       // Protocol Version - 4
                        0x02,                                       // Connect Flags
                        0x00, 0x3C,                                 // Keepalive - 60
                        0x00, 0x05, 0x73, 0x68, 0x65, 0x65, 0x70])  // ClientID - sheep
        
        conn.username = "abcd"
        conn.password = "pwd"
        conn.willMsg = CocoaMQTTMessage(topic: "t/1", string: "Banalana", qos: .qos2, retained: true)
        conn.cleansess = false
        
        XCTAssertEqual(conn.bytes(),
                       [0x10, 0x2B,
                        0x00, 0x04, 0x4D, 0x51, 0x54, 0x54,         // MQTT
                        0x04,                                       // Protocol Version - 4
                        0b11110100,                                 // Connect Flags - 0b11110100
                        0x00, 0x3C,                                 // Keepalive - 60
                        0x00, 0x05, 0x73, 0x68, 0x65, 0x65, 0x70,   // ClientId - sheep
                        0x00, 0x03, 0x74, 0x2F, 0x31,               // Will Topic - t/1
                        0x00, 0x08, 0x42, 0x61, 0x6E, 0x61, 0x6C, 0x61, 0x6E, 0x61, // Will Payload - Banalana
                        0x00, 0x04, 0x61, 0x62, 0x63, 0x64,         // Username - abcd
                        0x00, 0x03, 0x70, 0x77, 0x64])              // Password - pwd
    }
    
    func testFrameConAck() {
        var connack = FrameConnAck(code: .accept)
        var bytes = [UInt8](connack.bytes()[2...])
        var connack2 = FrameConnAck(fixedHeader: FrameType.connack.rawValue, bytes: bytes)
        
        XCTAssertEqual(connack.returnCode, connack2?.returnCode)
        XCTAssertEqual(connack.sessPresent, connack2?.sessPresent)
        
        connack.returnCode = .notAuthorized
        connack.sessPresent = true
        bytes = [UInt8](connack.bytes()[2...])
        connack2 = FrameConnAck(fixedHeader: FrameType.connack.rawValue, bytes: bytes)
        
        XCTAssertEqual(connack.returnCode, connack2?.returnCode)
        XCTAssertEqual(connack.sessPresent, connack2?.sessPresent)
    }
    
    func testFramePublish() {
        
        var publish = FramePublish(topic: "t/a", payload: "aaa".utf8 + [], qos: .qos0, msgid: 0x0010)
        var bytes = [UInt8](publish.bytes()[2...])
        var publish2 = FramePublish(fixedHeader: FrameType.publish.rawValue, bytes: bytes)
        
        XCTAssertEqual(publish.dup, publish2?.dup)
        XCTAssertEqual(publish.qos, publish2?.qos)
        XCTAssertEqual(publish.retained, publish2?.retained)
        XCTAssertEqual(publish.topic, publish2?.topic)
        XCTAssertEqual(publish.msgid, 0x0010)
        XCTAssertEqual(publish2?.msgid, 0)
        XCTAssertEqual(publish.payload(), publish2?.payload())
        

        publish.dup = false
        publish.retained = true
        publish.qos = .qos2
        publish.topic = "t/b"
        publish._payload = "bbb".utf8 + []
        
        
        bytes = [UInt8](publish.bytes()[2...])
        publish2 = FramePublish(fixedHeader: 0x35, bytes: bytes)
        
        XCTAssertEqual(publish.dup, publish2?.dup)
        XCTAssertEqual(publish.qos, publish2?.qos)
        XCTAssertEqual(publish.retained, publish2?.retained)
        XCTAssertEqual(publish.topic, publish2?.topic)
        XCTAssertEqual(publish.msgid, publish2?.msgid)
        XCTAssertEqual(publish.payload(), publish2?.payload())
        
        
        // -- Property GET/SET
        
        // PUBLISH - QOS2 - DUP - RETAINED
        guard var f0 = FramePublish(fixedHeader: 0x3D,
                                    bytes: [0x00, 0x03, 0x74, 0x2f, 0x61, // topic = t/a
                                            0x00, 0x10,                   // msgid = 16
                                            0x61, 0x61, 0x61]) else {     // payload = aaa
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(f0.fixedHeader, 0x3D)
        XCTAssertEqual(f0.type, FrameType.publish)
        XCTAssertEqual(f0.dup, true)
        XCTAssertEqual(f0.qos, .qos2)
        XCTAssertEqual(f0.retained, true)
        
        XCTAssertEqual(f0.topic, "t/a")
        XCTAssertEqual(f0.msgid, 16)
        XCTAssertEqual(f0.payload(), [0x61, 0x61, 0x61])
        
        f0.dup = false
        f0.qos = CocoaMQTTQoS.qos0
        f0.retained = false
    
        f0.dup = true
        XCTAssertEqual(f0.dup, true)
        f0.dup = false
        XCTAssertEqual(f0.dup, false)
        
        XCTAssertEqual(f0.qos, .qos0)
        f0.qos = CocoaMQTTQoS.qos1
        XCTAssertEqual(f0.qos, .qos1)
        f0.qos = CocoaMQTTQoS.qos2
        XCTAssertEqual(f0.qos, .qos2)
        f0.qos = CocoaMQTTQoS.qos0
        XCTAssertEqual(f0.qos, .qos0)

        XCTAssertEqual(f0.retained, false)
        f0.retained = true
        XCTAssertEqual(f0.retained, true)
        f0.retained = false
        XCTAssertEqual(f0.retained, false)
    }
    
    func testFramePubAck() {
        
        var puback = FramePubAck(msgid: 0x1010)
        var bytes = [UInt8](puback.bytes()[2...])
        var puback2 = FramePubAck(fixedHeader: FrameType.puback.rawValue, bytes: bytes)
        
        XCTAssertEqual(puback.fixedHeader, puback2?.fixedHeader)
        XCTAssertEqual(puback.msgid, puback2?.msgid)
        
        XCTAssertEqual(puback2?.fixedHeader, 0x40)
        XCTAssertEqual(puback2?.msgid, 0x1010)
        XCTAssertEqual(puback2?.bytes(), [0x40, 0x02, 0x10, 0x10])
        
        puback.msgid = 0x1011
        bytes = [UInt8](puback.bytes()[2...])
        puback2 = FramePubAck(fixedHeader: FrameType.puback.rawValue, bytes: bytes)
        
        XCTAssertEqual(puback.fixedHeader, puback2?.fixedHeader)
        XCTAssertEqual(puback.msgid, puback2?.msgid)
        
        XCTAssertEqual(puback2?.fixedHeader, 0x40)
        XCTAssertEqual(puback2?.msgid, 0x1011)
        XCTAssertEqual(puback2?.bytes(), [0x40, 0x02, 0x10, 0x11])
    }
    
    func testFramePubRec() {
        var pubrec = FramePubRec(msgid: 0x1010)
        var bytes = [UInt8](pubrec.bytes()[2...])
        var pubrec2 = FramePubRec(fixedHeader: FrameType.pubrec.rawValue, bytes: bytes)
        
        XCTAssertEqual(pubrec.fixedHeader, pubrec2?.fixedHeader)
        XCTAssertEqual(pubrec.msgid, pubrec2?.msgid)
        
        XCTAssertEqual(pubrec2?.fixedHeader, 0x50)
        XCTAssertEqual(pubrec2?.msgid, 0x1010)
        XCTAssertEqual(pubrec2?.bytes(), [0x50, 0x02, 0x10, 0x10])
        
        pubrec.msgid = 0x1011
        bytes = [UInt8](pubrec.bytes()[2...])
        pubrec2 = FramePubRec(fixedHeader: FrameType.pubrec.rawValue, bytes: bytes)
        
        XCTAssertEqual(pubrec.fixedHeader, pubrec2?.fixedHeader)
        XCTAssertEqual(pubrec.msgid, pubrec2?.msgid)
        
        XCTAssertEqual(pubrec2?.fixedHeader, 0x50)
        XCTAssertEqual(pubrec2?.msgid, 0x1011)
        XCTAssertEqual(pubrec2?.bytes(), [0x50, 0x02, 0x10, 0x11])
    }
    
    func testFramePubRel() {
     
        var pubrel = FramePubRel(msgid: 0x1010)
        var bytes = [UInt8](pubrel.bytes()[2...])
        var pubrel2 = FramePubRel(fixedHeader: 0x62, bytes: bytes)
        
        XCTAssertEqual(pubrel.fixedHeader, pubrel2?.fixedHeader)
        XCTAssertEqual(pubrel.msgid, pubrel2?.msgid)
        
        XCTAssertEqual(pubrel2?.fixedHeader, 0x62)
        XCTAssertEqual(pubrel2?.msgid, 0x1010)
        XCTAssertEqual(pubrel2?.bytes(), [0x62, 0x02, 0x10, 0x10])
        
        pubrel.msgid = 0x1011
        bytes = [UInt8](pubrel.bytes()[2...])
        pubrel2 = FramePubRel(fixedHeader: 0x62, bytes: bytes)
        
        XCTAssertEqual(pubrel.fixedHeader, pubrel2?.fixedHeader)
        XCTAssertEqual(pubrel.msgid, pubrel2?.msgid)
        
        XCTAssertEqual(pubrel2?.fixedHeader, 0x62)
        XCTAssertEqual(pubrel2?.msgid, 0x1011)
        XCTAssertEqual(pubrel2?.bytes(), [0x62, 0x02, 0x10, 0x11])
    }
    
    func testFramePubComp() {
        var pubcomp = FramePubComp(msgid: 0x1010)
        var bytes = [UInt8](pubcomp.bytes()[2...])
        var pubcomp2 = FramePubComp(fixedHeader: FrameType.pubcomp.rawValue, bytes: bytes)
        
        XCTAssertEqual(pubcomp.fixedHeader, pubcomp2?.fixedHeader)
        XCTAssertEqual(pubcomp.msgid, pubcomp2?.msgid)
        
        XCTAssertEqual(pubcomp2?.fixedHeader, 0x70)
        XCTAssertEqual(pubcomp2?.msgid, 0x1010)
        XCTAssertEqual(pubcomp2?.bytes(), [0x70, 0x02, 0x10, 0x10])
        
        pubcomp.msgid = 0x1011
        bytes = [UInt8](pubcomp.bytes()[2...])
        pubcomp2 = FramePubComp(fixedHeader: FrameType.pubcomp.rawValue, bytes: bytes)
        
        XCTAssertEqual(pubcomp.fixedHeader, pubcomp2?.fixedHeader)
        XCTAssertEqual(pubcomp.msgid, pubcomp2?.msgid)
        
        XCTAssertEqual(pubcomp2?.fixedHeader, 0x70)
        XCTAssertEqual(pubcomp2?.msgid, 0x1011)
        XCTAssertEqual(pubcomp2?.bytes(), [0x70, 0x02, 0x10, 0x11])
    }
    
    func testFrameSubscribe() {
        let subscribe = FrameSubscribe(msgid: 0x1010, topic: "topic", reqos: .qos1)
        XCTAssertEqual(subscribe.fixedHeader, 0x82)
        XCTAssertEqual(subscribe.msgid, 0x1010)
        XCTAssertEqual(subscribe.topics.count, 1)
        for (t, qos) in subscribe.topics {
            XCTAssertEqual(t, "topic")
            XCTAssertEqual(qos, .qos1)
        }
        XCTAssertEqual(subscribe.bytes(),
                       [0x82, 0x0A,
                        0x10, 0x10,
                        0x00, 0x05, 0x74, 0x6F, 0x70, 0x69, 0x63,
                        0x01])
    }
    
    func testFrameSubAck() {
        
        var suback = FrameSubAck(msgid: 0x1010, grantedQos: [.qos0, .FAILTURE, .qos2])
        var bytes = [UInt8](suback.bytes()[2...])
        var suback2 = FrameSubAck(fixedHeader: FrameType.suback.rawValue, bytes: bytes)
        
        XCTAssertEqual(suback.fixedHeader, suback2?.fixedHeader)
        XCTAssertEqual(suback.msgid, suback2?.msgid)
        XCTAssertEqual(suback.grantedQos, suback2?.grantedQos)
        
        XCTAssertEqual(suback2?.type, .suback)
        XCTAssertEqual(suback2?.qos, .qos0)
        XCTAssertEqual(suback2?.dup, false)
        XCTAssertEqual(suback2?.retained, false)
        XCTAssertEqual(suback2?.msgid, 0x1010)
        XCTAssertEqual(suback2?.grantedQos, [.qos0, .FAILTURE, .qos2])
        
        suback.msgid = 0x1011
        suback.grantedQos = [.qos0]
        bytes = [UInt8](suback.bytes()[2...])
        suback2 = FrameSubAck(fixedHeader: FrameType.suback.rawValue, bytes: bytes)
        
        XCTAssertEqual(suback.fixedHeader, suback2?.fixedHeader)
        XCTAssertEqual(suback.msgid, suback2?.msgid)
        XCTAssertEqual(suback.grantedQos, suback2?.grantedQos)
    }
    
    func testFrameUnsubscribe() {
        
        let unsub = FrameUnsubscribe(msgid: 0x1010, topics: ["topic", "t2"])

        XCTAssertEqual(unsub.fixedHeader, 0xA2)
        XCTAssertEqual(unsub.msgid, 0x1010)
        XCTAssertEqual(unsub.topics, ["topic", "t2"])
        XCTAssertEqual(unsub.bytes(),
                       [0xA2, 0x0d,
                        0x10, 0x10,
                        0x00, 0x05, 0x74, 0x6F, 0x70, 0x69, 0x63,
                        0x00, 0x02, 0x74, 0x32])
    }
    
    func testFrameUnsubAck() {
        
        var unsuback = FrameUnsubAck(msgid: 0x1010)
        var bytes = [UInt8](unsuback.bytes()[2...])
        var unsuback2 = FrameUnsubAck(fixedHeader: FrameType.unsuback.rawValue, bytes: bytes)
        
        XCTAssertEqual(unsuback.fixedHeader, unsuback2?.fixedHeader)
        XCTAssertEqual(unsuback.msgid, unsuback2?.msgid)
        XCTAssertEqual(unsuback2?.type, .unsuback)
        XCTAssertEqual(unsuback2?.dup, false)
        XCTAssertEqual(unsuback2?.qos, .qos0)
        XCTAssertEqual(unsuback2?.retained, false)
        
        unsuback.msgid = 0x1011
        bytes = [UInt8](unsuback.bytes()[2...])
        unsuback2 = FrameUnsubAck(fixedHeader: FrameType.unsuback.rawValue, bytes: bytes)
        
        XCTAssertEqual(unsuback.fixedHeader, unsuback2?.fixedHeader)
        XCTAssertEqual(unsuback.msgid, unsuback2?.msgid)
        XCTAssertEqual(unsuback2?.type, .unsuback)
        XCTAssertEqual(unsuback2?.dup, false)
        XCTAssertEqual(unsuback2?.qos, .qos0)
        XCTAssertEqual(unsuback2?.retained, false)
    }
    
    func testFramePing() {
        
        let ping = FramePingReq()
        
        XCTAssertEqual(ping.fixedHeader, 0xC0)
        XCTAssertEqual(ping.bytes(), [0xC0, 0x00])
    }
    
    func testFramePong() {
        
        let pong = FramePingResp()
        let bytes = [UInt8](pong.bytes()[2...])
        let pong2 = FramePingResp(fixedHeader: FrameType.pingresp.rawValue, bytes: bytes)
        
        XCTAssertEqual(pong.fixedHeader, pong2?.fixedHeader)
        XCTAssertEqual(pong.bytes(), [0xD0, 0x00])
    }
    
    func testFrameDisconnect() {
        
        let disconn = FrameDisconnect()
        
        XCTAssertEqual(disconn.fixedHeader, 0xE0)
        XCTAssertEqual(disconn.bytes(), [0xE0, 0x00])
    }
}
