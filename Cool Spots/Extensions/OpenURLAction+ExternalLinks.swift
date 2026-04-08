//
//  OpenURLAction+ExternalLinks.swift
//  Purpose: OpenURLAction helpers for opening Instagram handles and website URLs
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

extension OpenURLAction {
    func openInstagram(_ handle: String) {
        let clean = handle.trimmingCharacters(in: .init(charactersIn: "@"))
        if let url = URL(string: "https://instagram.com/\(clean)") { self(url) }
    }

    func openWebsite(_ urlString: String) {
        let prefixed = urlString.hasPrefix("http") ? urlString : "https://\(urlString)"
        if let url = URL(string: prefixed) { self(url) }
    }
}
