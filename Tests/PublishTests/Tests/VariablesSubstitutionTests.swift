import XCTest
import Files
import Publish

final class VariablesSubstitutionTests: PublishTestCase {
    func testSubstitutingVariablesInFile() throws {
        let folder = try Folder.createTemporary()

        try publishWebsite(in: folder, using: [
            .run { _ in
                try folder
                    .createFile(at: ".intermediate/index.md")
                    .write("Hello ${name}, this is an example of ${count} variables substitution.")

                try folder
                    .createFile(at: ".intermediate/excluded.txt")
                    .write("Hello ${name}, this file is excluded from substitution.")
            },
            .substituteVariables(
                using: VariablesConfiguration(
                    variables: [
                        "name": "world",
                        "count": "2"
                    ],
                    in: ["md"] // `.txt` file is not included
                )
            )
        ])

        XCTAssertEqual(
            try folder.file(at: ".intermediate/index.md").readAsString(),
            "Hello world, this is an example of 2 variables substitution."
        )
        XCTAssertEqual(
            try folder.file(at: ".intermediate/excluded.txt").readAsString(),
            "Hello ${name}, this file is excluded from substitution."
        )
    }
}

extension VariablesSubstitutionTests {
    static var allTests: Linux.TestList<VariablesSubstitutionTests> {
        [
            ("testSubstitutingVariablesInFile", testSubstitutingVariablesInFile),
        ]
    }
}

