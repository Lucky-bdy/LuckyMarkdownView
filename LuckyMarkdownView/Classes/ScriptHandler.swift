//
//  ScriptHandler.swift
//  LuckyMarkdownView-LuckyMarkdownView
//
//  Created by mac on 2025/9/26.
//

import Foundation
import WebKit


public class ScriptHandler: NSObject {
    
    var script: String
    var name: String
    
    public init(script: String, name: String) {
        self.script = script
        self.name = name
    }
    
    public func didReceive(message: WKScriptMessage) {
        
    }
}


extension ScriptHandler: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        didReceive(message: message)
    }
}


extension WKUserContentController {
    func addScriptHandler(handler: ScriptHandler) {
        removeScriptMessageHandler(forName: handler.name)
        add(handler, name: handler.name)
        if handler.script.count > 0 {
            addUserScript(WKUserScript(source: handler.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
    }
}



public class SelectionHandler: ScriptHandler {
    
    
    public init() {
        let script = """
            document.addEventListener('selectionchange', function() {
                var selection = window.getSelection();
                if (selection.rangeCount > 0) {
                    var range = selection.getRangeAt(0);
                    var rect = range.getBoundingClientRect();
                    var selectedText = selection.toString();
                    var position = { 
                        x: rect.left, 
                        y: rect.top, 
                        width: rect.width, 
                        height: rect.height 
                    };
                    window.webkit.messageHandlers.selectionHandler.postMessage({text: selectedText, position: position});
                } else {
                    // 如果没有选中文本，意味着用户取消选择
                    window.webkit.messageHandlers.selectionHandler.postMessage({text: '', position: null});
                }
            });
        """
        
        super.init(script: script, name: "selectionHandler")
    }
    
    public var funcForSelection: (String, CGRect) -> Void = { _,_ in }
    
    public override func didReceive(message: WKScriptMessage) {
        guard message.name == name,
              let messageBody = message.body as? [String: Any],
              let selectedText = messageBody["text"] as? String
        else {
            return
        }
        let position = messageBody["position"] as? [String: CGFloat]
        let x: CGFloat = position?["x"] ?? 0
        let y: CGFloat = position?["y"] ?? 0
        let width: CGFloat = position?["width"] ?? 0
        let height: CGFloat = position?["height"] ?? 0
        
        funcForSelection(selectedText, CGRect(x: x, y: y, width: width, height: height))
    }
}


public class UpdateContentHeightHandler: ScriptHandler {
    
    public init() {
        super.init(script: "", name: "updateHeight")
    }
    
    public var funcForUpdateHeight: (CGFloat) -> Void = { _ in }
    
    
    public override func didReceive(message: WKScriptMessage) {
        guard message.name == name,
              let height = message.body as? CGFloat
        else {
            return
        }
        funcForUpdateHeight(height)
    }
}


public class TapContentHandler: ScriptHandler {
    
    public init() {
        let script = """
                document.addEventListener('click', function () {
                    window.webkit.messageHandlers.webTouched.postMessage("tap");
                });
            """
        super.init(script: script, name: "webTouched")
    }
    
    public var funcForTapContent: () -> Void = {}
    
    public override func didReceive(message: WKScriptMessage) {
        guard message.name == name else {
            return
        }
        funcForTapContent()
    }
}



extension WKUserScript {
    
    public convenience init(markdown: String) {
        self.init(source: "window.showMarkdown('\(markdown)', 'true');", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}
