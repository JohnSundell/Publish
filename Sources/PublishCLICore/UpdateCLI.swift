//
//  File.swift
//  
//
//  Created by 游宗諭 on 2020/1/2.
//


import Foundation
import Files
import ShellOut

internal struct UpdateCLI {
	let tmpDir:String = "$TMPDIR/Publish"
	let publishRepositoryURL:URL
	var tmpGit:String {"git --git-dir=\(tmpDir)/.git  --work-tree=\(tmpDir)"}
	
	func run() throws {
		print("updating")
		try shellOut(to: "echo `\(tmpDir)`")
		if let _ = try? shellOut(to: .gitClone(url: publishRepositoryURL, to:  tmpDir)) {
			
		}
		else {
			let thisVersion = try shellOut(to: "\(tmpGit) describe --abbrev=0 --tags")
			let remoteLatestVersion = try shellOut(to: #"\#(tmpGit) ls-remote --tags --refs --sort="v:refname" origin | tail -n1 | sed 's/.*\///'"#)
			guard thisVersion < remoteLatestVersion else {
				return print("publish is up to date")
			}
			try shellOut(to: "\(tmpGit) pull")
			print("✅ publish updating to \(remoteLatestVersion)")
		}
		try	shellOut(to: [
			"make -f \(tmpDir)/Makefile"
		])
		print("✅ update complete")
	}
}

