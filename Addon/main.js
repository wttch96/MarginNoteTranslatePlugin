JSB.newAddon = function (mainPath) {
    // 翻译调用的 url 路径
    const baseUrl = "WttchTranslate://keyword/";
    const isOnKey = 'marginnote_wttchtranslate';
    const showHUD = Application.sharedInstance().showHUD;
    //MARK: - Customized functions
    // 生成翻译URL
    function generateUrl(keyWords) {
        return baseUrl + keyWords;
    }

    // 打开翻译请求的 url
    function openUrlWithExternalBrowser(url) {
        let encodedUrl = encodeURI(url);
        let nsURL = NSURL.URLWithString(encodedUrl);
        let app = UIApplication.sharedApplication();
        let result = app.openURLOptionsCompletionHandler(nsURL, {}, function () {
        });
    }

    // 尝试发送翻译请求
    function trySendTranslateRequest(text) {
        try {
            if (text && text.length) {
                text = text.replace(/^\s+/, '').replace(/\s+$/, ''); //去除首尾空格
                let url = generateUrl(text);
                openUrlWithExternalBrowser(url);
            }
        } catch (e) {
            showHUD(e, self.window, 2);
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

            trySendTranslateRequest(text)
        },

        // 选择笔记翻译
        onPopupMenuOnNote: function (sender) {
            if (!Application.sharedInstance().checkNotifySenderInWindow(sender, self.window) || !self.wttchTranslateIsOn) {
                return;
            }
            var text = sender.userInfo.note.noteTitle;
            if (!text) {
                text = sender.userInfo.note.excerptText;
            }
            trySendTranslateRequest(text)
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
