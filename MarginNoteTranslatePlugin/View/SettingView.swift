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
    @AppStorage(.youdaoAppID) var youdaoAppId: String = ""
    @AppStorage(.youdaoAppKey) var youdaoAppKey: String = ""
    // 讯飞翻译
    @AppStorage(.xunfeiAppID) private var xunfeiAppID: String = ""
    @AppStorage(.xunfeiAppSecret) private var xunfeiAppSecret: String = ""
    @AppStorage(.xunfeiAppKey) private var xunfeiAppKey: String = ""
    
    // deepseek
    @AppStorage(.deepseekKey) private var deepseekKey: String = ""
    @AppStorage(.deepseekTranslatePrompt‌) private var deepseekTranslatePrompt: String = ""
    @AppStorage(.deepseekSummaryPrompt) private var deepseekSummaryPrompt: String = ""
    
    @State private var accounts: [TanshuAccountDTO] = []
    
    @State private var anyCancellable: AnyCancellable? = nil
    @State private var error: String? = nil
    
    @AppStorage(.apiType) private var apiType: APIType = .tanshu
    @AppStorage(.tanshuType) private var tanshuType: TanshuAPIType = .deepl
    
    var body: some View {
        TabView {
            Tab(content: { deepseekSettingView }, label: { Text("Deepseek") })
            
            Tab(content: {
                Form {
                    apiPicker
                    if apiType == .tanshu {
                        tanshuTypePicker
                    }
                }
                .formStyle(.grouped)
            }, label: {
                Text("翻译配置")
            })
            Tab(content: {
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
            }, label: {
                Text("API配置")
            })
        }
        .tabViewStyle(.tabBarOnly)
        .padding()
        .frame(width: 600)
        .formStyle(.grouped)
    }
}

extension SettingView {
    // deepseek
    @ViewBuilder
    private var deepseekSettingView: some View {
        Form {
            DisplayableSecureField("API Key", text: $deepseekKey)
            
            Section("翻译提示词", content: {
                TextEditor(text: $deepseekTranslatePrompt)
                    .frame(height: 120)
            })
            
            Section("总结提示词", content: {
                TextEditor(text: $deepseekSummaryPrompt)
                    .frame(height: 120)
            })
        }
    }
    
    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.largeTitle)
            .bold()
    }
    
    // 使用的 API 的选择器
    @ViewBuilder
    private var apiPicker: some View {
        Picker("翻译API", selection: $apiType, content: {
            ForEach(APIType.allCases) { api in
                Text(api.name)
                    .tag(api)
            }
        })
    }
    
    
    @ViewBuilder
    // 探数 API 翻译引擎选择
    private var tanshuTypePicker: some View {
        Picker("探数翻译引擎", selection: $tanshuType) {
            ForEach(TanshuAPIType.allCases, id: \.rawValue) { api in
                Text(api.rawValue)
                    .tag(api)
            }
        }
    }

}

#Preview {
    SettingView()
}
