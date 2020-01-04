//
//  File.swift
//  
//
//  Created by 游宗諭 on 2020/1/4.
//

import Foundation
import Files

internal struct NewContentGenerator {
	private let folder: Folder
	private let siteName: String
	private let filePath: String
	private var path: String {
		var path = filePath.split(separator: "/")
		path.removeLast()
		return path.joined(separator: "/")
	}
	private var fileName:String {
		return String(filePath.split(separator: "/").last!)
	}
	init(folder: Folder,
		 filePath:String) {
		self.folder = folder
		self.siteName = String(folder.name.capitalized.filter { $0.isLetter })
		self.filePath = filePath
	}
	private var file:File!
	
	func generate() throws {

		try generateContent()
	}
}

private extension NewContentGenerator {

	
	func generateContent() throws {
		let folder = try self.folder.subfolder(named: "Content")
		let contentFolder:Folder
		if path.isEmpty {
			var postsFolder = try? folder.subfolder(named: "posts")
			if postsFolder == nil {
				postsFolder = try folder.createSubfolder(at: "posts")
			}
			contentFolder = postsFolder!
		} else {
			var postsFolder = try? folder.subfolder(named: path)
			if postsFolder == nil {
				postsFolder = try folder.createSubfolder(at: path)
			}
			contentFolder = postsFolder!
		}
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
		dateFormatter.timeZone = .current
		var fileName = self.fileName
		if !fileName.hasSuffix(".md") {
			fileName += ".md"
		}
		let file = try contentFolder.createFile(named: fileName)
			
		try file.write(
			"""
			---
			date: \(dateFormatter.string(from: Date()))
			description: A description of this content.
			tags:
			---
			# <#New Content Title#>
			
			""")
		print("""
			✅ Generated new content at \(file.path)
			""")
	}
	
}

private extension Folder {
	func createIndexFile(withMarkdown markdown: String) throws {
		try createFile(named: "index.md").write(markdown)
	}
}
