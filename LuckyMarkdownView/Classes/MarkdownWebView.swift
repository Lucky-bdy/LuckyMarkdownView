//
//  MarkdownWebView.swift
//  LuckyMarkdownView
//
//  Created by mac on 2025/9/26.
//

import UIKit
import WebKit

public class MarkdownWebView: WKWebView {

    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    public override func buildMenu(with builder: any UIMenuBuilder) {
            
        builder.remove(menu: .learn)
        builder.remove(menu: .lookup)
        builder.remove(menu: .share)
        
        super.buildMenu(with: builder)
    }

    
    
    public private(set) var configuation: WKWebViewConfiguration
    public private(set) var updateHeightHandler: UpdateContentHeightHandler
    var selectionHandler: SelectionHandler
    var tapContentHandler: TapContentHandler
    
    
    public init(configuation: WKWebViewConfiguration = .init(), updateHeightHandler: UpdateContentHeightHandler = .init(), selectionHandler: SelectionHandler = .init(), tapContentHandler: TapContentHandler = .init()) {
        
        self.configuation = configuation
        self.updateHeightHandler = updateHeightHandler
        self.selectionHandler = selectionHandler
        self.tapContentHandler = tapContentHandler
        self.configuation.userContentController.addScriptHandler(handler: self.updateHeightHandler)
        self.configuation.userContentController.addScriptHandler(handler: self.selectionHandler)
        self.configuation.userContentController.addScriptHandler(handler: self.tapContentHandler)
        super.init(frame: .zero, configuration: self.configuation)
        if let style = String.styledHtmlUrl {
            load(URLRequest(url: style))
        }
        navigationDelegate = self
        uiDelegate = self
        
        self.selectionHandler.funcForSelection = { [weak self] text, rect in
            guard let weakself = self else { return }
            if weakself.selectable == false {
                weakself.cancelSelectText()
            }
            weakself.funcForSelect(text, rect)
        }
        self.tapContentHandler.funcForTapContent = funcForTapContent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public var selectable: Bool = false
    
    public var funcForSelect: (String, CGRect) -> Void = { _, _ in }
    public var funcForTapContent: () -> Void = {}
    
}


extension MarkdownWebView: WKNavigationDelegate, WKUIDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        
        return .allow
    }
}

extension MarkdownWebView {
    
    public func selectTextAtCoordinates(x: CGFloat, y: CGFloat) {
        
        let script = """
            var element = document.elementFromPoint(\(x), \(y));
            if (element) {
                var range = document.createRange();
                range.selectNodeContents(element);
                var selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);
            }
        """
        
        evaluateJavaScript(script, completionHandler: nil)
    }
    
    
    public func cancelSelectText() {
        becomeFirstResponder()
        
        let script = """
            var selection = window.getSelection();
            selection.removeAllRanges();
        """
        
        evaluateJavaScript(script, completionHandler: nil)
    }
    
    public func load(markdown: String) {
        let markdown = markdown.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        configuration.userContentController.removeAllUserScripts()
        let us = WKUserScript(markdown: markdown)
        configuration.userContentController.addUserScript(us)
        configuation.userContentController.addScriptHandler(handler: selectionHandler)
        configuation.userContentController.addScriptHandler(handler: updateHeightHandler)
        reload()
    }
    
    
}
