import NIO
import Files
import NIOCore
import NIOHTTP1
import NIOFileSystem
import UniformTypeIdentifiers

extension Website {
    public func serve(
        at path: Path? = nil,
        host: String = "0.0.0.0",
        port: Int = 8080,
        file: StaticString = #filePath
    ) async throws {
        let root = try FilePath(resolveRootFolder(withExplicitPath: path, file: file).path).appending("Output")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let channel = try await ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .bind(host: host, port: port) { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.configureHTTPServerPipeline(withErrorHandling: true)

                    return try NIOAsyncChannel(
                        wrappingChannelSynchronously: channel,
                        configuration: .init(
                            inboundType: HTTPServerRequestPart.self,
                            outboundType: HTTPServerResponsePart.self
                        )
                    )
                }
            }

        print("🚀 Server running at \(host):\(port)")

        try await withThrowingDiscardingTaskGroup { group in
            try await channel.executeThenClose { inbound in
                for try await connectionChannel in inbound {
                    group.addTask {
                        try await handleConnection(channel: connectionChannel, root: root)
                    }
                }
            }
        }

        try await eventLoopGroup.shutdownGracefully()
    }

    fileprivate func resolveRootFolder(withExplicitPath path: Path?, file: StaticString) throws -> Folder {
        if let path = path {
            return try Folder(path: path.string)
        }

        return try File(path: "\(file)").resolveSwiftPackageFolder()
    }

    fileprivate func handleConnection(channel: NIOAsyncChannel<HTTPServerRequestPart, HTTPServerResponsePart>, root: FilePath) async throws {
        do {
            try await channel.executeThenClose { inbound, outbound in
                var head: HTTPRequestHead!
                var body = ByteBuffer()

                for try await data in inbound {
                    switch data {
                    case .head(let requestHead):
                        head = requestHead
                    case .body(var requestBody):
                        body.writeBuffer(&requestBody)
                    case .end(_):
                        try await handle(request: head, body: body, output: outbound, root: root)
                    }
                }

                outbound.finish()
            }
        }
    }

    fileprivate func respond404(_ output: NIOAsyncChannelOutboundWriter<HTTPServerResponsePart>, _ request: HTTPRequestHead) async throws {
        try await output.write(.head(.init(version: request.version, status: .notFound, headers: .init([("Content-Size", "0")]))))
        try await output.write(.end(nil))
    }

    fileprivate func handle(request: HTTPRequestHead, body: ByteBuffer, output: NIOAsyncChannelOutboundWriter<HTTPServerResponsePart>, root: FilePath) async throws {
        let filePath = root
            .appending(FilePath(request.uri.removingPercentEncoding ?? "/").components)
            .lexicallyNormalized()

        guard filePath.starts(with: root) else {
            try await respond404(output, request)
            return
        }

        guard let info = try await FileSystem.shared.info(forFileAt: filePath), info.type == .regular || info.type == .directory else {
            try await respond404(output, request)
            return
        }
        do {
            let file: FilePath
            let fileSize: Int64
            if info.type == .directory {
                file = filePath.appending("index.html")
                fileSize = try await FileSystem.shared.info(forFileAt: file).map(\.size) ?? 0
            } else {
                file = filePath
                fileSize = info.size
            }

            let contentType = file.extension.flatMap { UTType(filenameExtension: $0) } ?? .plainText
            let fileHandle = try await FileSystem.shared.openFile(forReadingAt: file)

            do {

                let responseHead = HTTPResponseHead(
                    version: request.version,
                    status: .ok,
                    headers: .init(
                        [
                            ("Content-Length", "\(fileSize)"),
                            ("Content-Type", contentType.preferredMIMEType ?? "text/plain")
                        ]
                    )
                )

                try await output.write(.head(responseHead))
                for try await chunk in fileHandle.readChunks() {
                    try await output.write(.body(.byteBuffer(chunk)))
                }

                try await output.write(.end(nil))
                try await fileHandle.close()

            } catch {
                try await fileHandle.close()
                throw error
            }
        } catch {
            print("❌ \(error)")
        }
    }

}
