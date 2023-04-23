/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

/// Closure type used to implement content mutations.
public typealias Mutations<T> = (inout T) throws -> Void
public typealias HTMLIndexMutation<Site:Website> = (PublishingContext<Site>, String) throws -> String
public typealias HTMLSectionMutation<Site:Website> = (PublishingContext<Site>, Section<Site>, String) throws -> String
public typealias HTMLItemMutation<Site:Website> = (PublishingContext<Site>, Item<Site>, String) throws -> String
public typealias HTMLPageMutation<Site:Website> = (PublishingContext<Site>, Page, String) throws -> String
public typealias HTMLAllMutation<Site:Website> = (PublishingContext<Site>, Location, String) throws -> String
