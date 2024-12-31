JSB.newAddon = function (mainPath) {
    // 翻译调用的 url 路径
    const baseUrl = "WttchTranslate://keyword";
    const isOnKey = 'marginnote_wttchtranslate';
    //MARK: - Customized functions
    // 生成翻译URL
    function generateUrl(type, data) {
        let jsonString = JSON.stringify(data);
        let encodedString = encodeURIComponent(jsonString);
        return baseUrl + "?type=" + type + "&data=" + encodedString;
    }

    // 打开翻译请求的 url
    function openUrlWithExternalBrowser(url) {
        let encodedUrl = encodeURI(url);
        let nsURL = NSURL.URLWithString(encodedUrl);
        let app = UIApplication.sharedApplication();
        let result = app.openURLOptionsCompletionHandler(nsURL, {}, function () {
        });
    }


    /**
     * 发送翻译请求
     * @param type 翻译类型
     * @param data 翻译数据, json 格式
     */
    function sendTranslateRequest(type, data) {
        try {
            let uriString = generateUrl(type, data);
            // Application.sharedInstance().showHUD("正在发送翻译请求..." + uriString, self.window, 2);
            openUrlWithExternalBrowser(uriString);
        } catch (e) {
            Application.sharedInstance().showHUD(e, self.window, 2);
        }
    }

    //MARK - Addon Class definition
    return JSB.defineClass('WttchTranslateAddon : JSExtension', {
        // MARK: - Instance Method Definitions
        // Window initialize
        sceneWillConnect: function () {
        }, // Window disconnect
        sceneDidDisconnect: function () {
        }, // Window resign active
        sceneWillResignActive: function () {
        }, // Window become active
        sceneDidBecomeActive: function () {
        }, //MARK: MN behaviors
        notebookWillOpen: function (notebookid) {
            NSNotificationCenter.defaultCenter().addObserverSelectorName(self, 'onPopupMenuOnSelection:', 'PopupMenuOnSelection');
            NSNotificationCenter.defaultCenter().addObserverSelectorName(self, 'onPopupMenuOnNote:', 'PopupMenuOnNote');
            self.wttchTranslateIsOn = NSUserDefaults.standardUserDefaults().objectForKey(isOnKey);
        }, notebookWillClose: function (notebookid) {
            NSNotificationCenter.defaultCenter().removeObserverName(self, 'PopupMenuOnSelection');
            NSNotificationCenter.defaultCenter().removeObserverName(self, 'PopupMenuOnNote');
        }, documentDidOpen: function (docmd5) {
        }, docmentWillClose: function (docmd5) {
        }, controllerWillLayoutSubviews: function (controller) {
        }, queryAddonCommandStatus: function () {
            if (Application.sharedInstance().studyController(self.window).studyMode < 3) {
                return {
                    image: 'fanyi.png',
                    object: self,
                    selector: "toggleWttchTranslate:",
                    checked: self.wttchTranslateIsOn
                };
            }
            return null;
        },

        // Select text and open the external Browser to process the selected Text
        onPopupMenuOnSelection: function (sender) {
            if (!Application.sharedInstance().checkNotifySenderInWindow(sender, self.window) || !self.wttchTranslateIsOn) {
                return;
            }
            const text = sender.userInfo.documentController.selectionText;

            sendTranslateRequest("selection", text);
        },

        // 选择笔记翻译
        onPopupMenuOnNote: function (sender) {
            if (!Application.sharedInstance().checkNotifySenderInWindow(sender, self.window) || !self.wttchTranslateIsOn) {
                return;
            }
            let note = sender.userInfo.note;
            sendTranslateRequest("note", {
                title: note.noteTitle,
                comments: note.comments,
                excerpt: note.excerptText
            });
        },

        // Add-On Switch
        toggleWttchTranslate: function (sender) {
            var lan = NSLocale.preferredLanguages().length ? NSLocale.preferredLanguages()[0].substring(0, 2) : 'en';
            let tips = lan === 'zh' ? 'Wttch翻译插件已关闭' : 'WttchTranslate is off';
            if (self.wttchTranslateIsOn) {
                self.wttchTranslateIsOn = false;
            } else {
                self.wttchTranslateIsOn = true;
                tips = lan === 'zh' ? 'Wttch翻译插件以打开，所选文字将发送给翻译插件处理' : 'Wttch translation plugin is now active, the selected text will be sent to the translation plugin for processing.';
            }
            Application.sharedInstance().showHUD(tips, self.window, 2);
            NSUserDefaults.standardUserDefaults().setObjectForKey(self.wttchTranslateIsOn, isOnKey);
            Application.sharedInstance().studyController(self.window).refreshAddonCommands();

        },
    }, {
        //MARK: - Class Method Definitions
        addonDidConnect: function () {
        }, addonWillDisconnect: function () {
        }, applicationWillEnterForeground: function () {
        }, applicationDidEnterBackground: function () {
        }, applicationDidReceiveLocalNotification: function (notify) {
        },
    });
};
