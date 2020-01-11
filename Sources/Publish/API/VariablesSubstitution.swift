import Foundation
import Files
import ShellOut

public struct VariablesConfiguration {
    let variables: [String: String]
    let fileExtensions: Set<String>

    public init(variables: [String: String], in fileExtensions: Set<String>) {
        self.variables = variables
        self.fileExtensions = fileExtensions
    }
}

internal struct VariablesSubstitution {
    let configuration: VariablesConfiguration

    func recursivelySubstituteVariables(in folder: Folder) throws {
        try folder.files
            .filter { configuration.fileExtensions.contains($0.extension ?? "") }
            .forEach { file in try substituteVariables(in: file) }
        try folder.subfolders.forEach { folder in try recursivelySubstituteVariables(in: folder) }
    }

    private func substituteVariables(in file: File) throws {
        try configuration.variables.forEach { (variableName, variableValue) in
            let newContent = try shellOut(to: "sed 's/${\(variableName)}/\(variableValue)/g' \(file.path)")
            try file.write(newContent)
        }
    }
}
