//
//  MenuBarView.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import SwiftUI
import Combine


class MenuBarViewModel: ObservableObject {
    @AppStorage("key") private var key: String?
    
    @Published var loading = false
    
    @Published var error: String? = nil
    
    @Published var accounts: [AccountDTO] = []
    
    private var anyCancellable: AnyCancellable? = nil
    
    func loadAccounts() {
        guard !self.loading else { return }
        
        guard let key = self.key else {
            self.error = "未找到 api key."
            print("未找到 探数 API key...")
            return
        }
        
        print("开始加载探数 API 使用情况...")
    
        DispatchQueue.main.async {
            self.accounts = []
            self.loading = true
            self.error = nil
        }
        
        anyCancellable = TanshuAPI.shared.accounts(key)
            .sink { error in
                self.loading = false
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            } receiveValue: { accounts in
                self.accounts = accounts
            }

    }
}

struct MenuBarView: View {
    @StateObject private var vm = MenuBarViewModel()
    @State var isVisibleObservation: NSKeyValueObservation? = nil
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack {
            Text("MarginNote 翻译插件")
                .foregroundColor(.green)
            Divider()
            
            Image(systemName: "gearshape.fill")
                .onTapGesture {
                    openWindow(id: "SettingWindow")
                }
            
            if let error = vm.error {
                Text(error)
                    .foregroundColor(.red)
            }
            
            ForEach(vm.accounts, id: \.apiId) { account in
                HStack {
                    Text(account.apiName)
                    Text("\(account.remainNum)/\(account.totalNum)")
                }
            }
            
            
            Divider()
            
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
        .viewIdentifier("MenuBarView")
        .padding(.vertical, 24)
        .onAppear {
            // 监听 window 的弹出事件
            WindowContext.shared.popoverWindow { window in
                isVisibleObservation = window.observe(\.isVisible, options: [.new]) { (window, change) in
                    if let isVisible = change.newValue {
                        if isVisible {
                            vm.loadAccounts()
                        }
                    }
                }
            }
        }
    }
    
}

#Preview {
    MenuBarView()
}
