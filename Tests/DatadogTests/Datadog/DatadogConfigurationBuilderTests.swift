/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import Datadog

class DatadogConfigurationBuilderTests: XCTestCase {
    func testDefaultBuilder() {
        let configuration = Datadog.Configuration
            .builderUsing(clientToken: "abc-123", environment: "tests")
            .build()

        let rumConfiguration = Datadog.Configuration
            .builderUsing(rumApplicationID: "rum-app-id", clientToken: "abc-123", environment: "tests")
            .build()

        XCTAssertFalse(configuration.rumEnabled)
        XCTAssertTrue(rumConfiguration.rumEnabled)

        XCTAssertNil(configuration.rumApplicationID)
        XCTAssertEqual(rumConfiguration.rumApplicationID, "rum-app-id")

        [configuration, rumConfiguration].forEach { configuration in
            XCTAssertEqual(configuration.clientToken, "abc-123")
            XCTAssertEqual(configuration.environment, "tests")
            XCTAssertTrue(configuration.loggingEnabled)
            XCTAssertTrue(configuration.tracingEnabled)
            XCTAssertEqual(configuration.logsEndpoint.url, "https://mobile-http-intake.logs.datadoghq.com/v1/input/")
            XCTAssertEqual(configuration.tracesEndpoint.url, "https://public-trace-http-intake.logs.datadoghq.com/v1/input/")
            XCTAssertEqual(configuration.rumEndpoint.url, "https://rum-http-intake.logs.datadoghq.com/v1/input/")
            XCTAssertNil(configuration.serviceName)
            XCTAssertNil(configuration.firstPartyHosts)
            XCTAssertEqual(configuration.rumSessionsSamplingRate, 100.0)
            XCTAssertNil(configuration.rumUIKitViewsPredicate)
            XCTAssertFalse(configuration.rumUIKitActionsTrackingEnabled)
        }
    }

    func testCustomizedBuilder() {
        func customized(_ builder: Datadog.Configuration.Builder) -> Datadog.Configuration.Builder {
            builder
                .set(serviceName: "service-name")
                .enableLogging(false)
                .enableTracing(false)
                .enableRUM(false)
                .set(logsEndpoint: .eu)
                .set(tracesEndpoint: .eu)
                .set(rumEndpoint: .eu)
                .track(firstPartyHosts: ["example.com"])
                .set(rumSessionsSamplingRate: 42.5)
                .trackUIKitRUMViews(using: UIKitRUMViewsPredicateMock())
                .trackUIKitActions(true)
        }

        let defaultBuilder = Datadog.Configuration
            .builderUsing(clientToken: "abc-123", environment: "tests")
        let defaultRUMBuilder = Datadog.Configuration
            .builderUsing(rumApplicationID: "rum-app-id", clientToken: "abc-123", environment: "tests")

        let configuration = customized(defaultBuilder).build()
        let rumConfiguration = customized(defaultRUMBuilder).build()

        XCTAssertNil(configuration.rumApplicationID)
        XCTAssertEqual(rumConfiguration.rumApplicationID, "rum-app-id")

        [configuration, rumConfiguration].forEach { configuration in
            XCTAssertEqual(configuration.clientToken, "abc-123")
            XCTAssertEqual(configuration.environment, "tests")
            XCTAssertEqual(configuration.serviceName, "service-name")
            XCTAssertFalse(configuration.loggingEnabled)
            XCTAssertFalse(configuration.tracingEnabled)
            XCTAssertFalse(configuration.rumEnabled)
            XCTAssertEqual(configuration.logsEndpoint.url, "https://mobile-http-intake.logs.datadoghq.eu/v1/input/")
            XCTAssertEqual(configuration.tracesEndpoint.url, "https://public-trace-http-intake.logs.datadoghq.eu/v1/input/")
            XCTAssertEqual(configuration.rumEndpoint.url, "https://rum-http-intake.logs.datadoghq.eu/v1/input/")
            XCTAssertEqual(configuration.firstPartyHosts, ["example.com"])
            XCTAssertEqual(configuration.rumSessionsSamplingRate, 42.5)
            XCTAssertNotNil(configuration.rumUIKitViewsPredicate)
            XCTAssertTrue(configuration.rumUIKitActionsTrackingEnabled)
        }
    }

    func testDeprecatedAPIs() {
        let builder = Datadog.Configuration.builderUsing(clientToken: "abc-123", environment: "tests")
        _ = (builder as ConfigurationBuilderDeprecatedAPIs).set(tracedHosts: ["example.com"])
        let configuration = builder.build()

        XCTAssertEqual(configuration.firstPartyHosts, ["example.com"])
    }
}

/// An assistant protocol to shim the deprecated APIs and call them with no compiler warning.
private protocol ConfigurationBuilderDeprecatedAPIs {
    func set(tracedHosts: Set<String>) -> Datadog.Configuration.Builder
}
extension Datadog.Configuration.Builder: ConfigurationBuilderDeprecatedAPIs {}
