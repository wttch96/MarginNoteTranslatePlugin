//
//  SettingView.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import Combine
import SwiftUI

///
/// 设置页面
///
struct SettingView: View {
    @AppStorage(.tanshuAPIKey) private var key: String = ""
    // 有道翻译
    @AppStorage(YoudaoAPI.appIdKey) var youdaoAppId: String = ""
    @AppStorage(YoudaoAPI.appKeyKey) var youdaoAppKey: String = ""
    // 讯飞翻译
    @AppStorage(.xunfeiAppID) private var xunfeiAppID: String = ""
    @AppStorage(.xunfeiAppSecret) private var xunfeiAppSecret: String = ""
    @AppStorage(.xunfeiAppKey) private var xunfeiAppKey: String = ""
    
    @State private var accounts: [TanshuAccountDTO] = []
    
    @State private var anyCancellable: AnyCancellable? = nil
    @State private var error: String? = nil
    
    var body: some View {
        Form {
            Section(content: {
                DisplayableSecureField("Key:", text: $key)
                if let error = self.error {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    ForEach(accounts, id: \.apiId) { account in
                        HStack(alignment: .center, spacing: 0) {
                            Text(account.apiName)
                            Spacer()
                            Text("\(account.remainNum)")
                                .foregroundColor(.green)
                            Text("/")
                            Text("\(account.totalNum)")
                                .font(.title)
                                .bold()
                        }
                    }
                }
            }, header: { sectionHeader("探数翻译") })
            .onAppear {
                let req = URLRequest(url: URL(string: "https://api.tanshuapi.com/api/account_info/v1/index?key=\(key)")!)
                
                self.anyCancellable = URLSession.shared.dataTaskPublisher(for: req)
                    .subscribe(on: DispatchQueue.global(qos: .background))
                    .tryMap {
                        $0.data
                    }
                    .decode(type: TanshuResponseDTO<TanshuListData<TanshuAccountDTO>>.self, decoder: JSONDecoder())
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
                    .sink { error in
                        switch error {
                        case .finished:
                            break
                        case .failure(let error):
                            self.error = error.localizedDescription
                            print(error)
                        }
                    } receiveValue: { resp in
                        accounts = resp.data.list
                    }
            }
            
            Section(content: {
                DisplayableSecureField("AppID:", text: $youdaoAppId)
                DisplayableSecureField("AppKey:", text: $youdaoAppKey)
            }, header: { sectionHeader("有道翻译") })
            
            Section(content: {
                TextField("AppID", text: $xunfeiAppID)
                DisplayableSecureField("AppSecret", text: $xunfeiAppSecret)
                DisplayableSecureField("AppKey", text: $xunfeiAppKey)
            }, header: { sectionHeader("讯飞翻译") })
        }
        .padding(.horizontal, 20)
        .padding(.vertical)
        .frame(width: 600)
        .formStyle(.grouped)
    }
}

extension SettingView {
    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.largeTitle)
            .bold()
    }
}

#Preview {
    SettingView()
}
