import WordPressKit

protocol PluginPresenter: class {
    func present(plugin: PluginState, capabilities: SitePluginCapabilities)
}

enum PluginListViewModel {
    case loading
    case ready(SitePlugins)
    case error(String)

    init(plugins: SitePlugins?) {
        switch plugins {
        case .none:
            self = .loading
        case .some(let plugins):
            self = .ready(plugins)
        }
    }

    var noResultsViewModel: WPNoResultsView.Model? {
        switch self {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Plugins...", comment: "Text displayed while loading plugins for a site")
            )
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: ""),
                    message: NSLocalizedString("There was an error loading plugins", comment: ""),
                    buttonTitle: NSLocalizedString("Contact support", comment: "")
                )
            } else {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("No connection", comment: ""),
                    message: NSLocalizedString("An active internet connection is required to view plugins", comment: "")
                )
            }
        }
    }

    func tableViewModel(presenter: PluginPresenter) -> ImmuTable {
        switch self {
        case .loading, .error:
            return .Empty
        case .ready(let sitePlugins):
            let rows = sitePlugins.plugins.map({ pluginState in
                return PluginListRow(
                    name: pluginState.name,
                    state: pluginState.stateDescription,
                    action: { [weak presenter] (row) in
                        presenter?.present(plugin: pluginState, capabilities: sitePlugins.capabilities)
                })
            })
            return ImmuTable(sections: [
                ImmuTableSection(rows: rows)
                ])
        }
    }
}
