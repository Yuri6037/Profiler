#!/bin/sh

swift run -c release --package-path BuildTools swiftformat --swiftversion 5.8.1 --disable andOperator "Profiler"
swift run -c release --package-path BuildTools swiftformat --swiftversion 5.8.1 --disable andOperator "ProfilerTests"
swift run -c release --package-path BuildTools swiftformat --swiftversion 5.8.1 --disable andOperator "ProfilerUITests"
swift run -c release --package-path BuildTools swiftformat --swiftversion 5.8.1 --disable andOperator "Protocol"
swift run -c release --package-path BuildTools swiftformat --swiftversion 5.8.1 --disable andOperator "ProtocolTests"
swift run -c release --package-path BuildTools swiftformat --swiftversion 5.8.1 --disable andOperator "TextTools"
swift run -c release --package-path BuildTools swiftformat --swiftversion 5.8.1 --disable andOperator "TextToolsTests"
