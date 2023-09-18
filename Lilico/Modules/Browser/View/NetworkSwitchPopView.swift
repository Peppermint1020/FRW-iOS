//
//  NetworkSwitchPopView.swift
//  Flow Reference Wallet
//
//  Created by Selina on 21/7/2023.
//

import SwiftUI

class NetworkSwitchPopViewModel: ObservableObject {
    @Published var fromNetwork: LocalUserDefaults.FlowNetworkType
    @Published var toNetwork: LocalUserDefaults.FlowNetworkType
    
    var descString: AttributedString {
        let normalDict = [NSAttributedString.Key.foregroundColor: UIColor.LL.Neutrals.text2]
        let fromHighlightDict = [NSAttributedString.Key.foregroundColor: fromNetwork.color.toUIColor()!]
        let toHighlightDict = [NSAttributedString.Key.foregroundColor: toNetwork.color.toUIColor()!]
        
        let str = NSMutableAttributedString(string: "switch_network_tips_msg_slice_0".localized, attributes: normalDict)
        str.append(NSAttributedString(string: " ", attributes: normalDict))
        str.append(NSAttributedString(string: fromNetwork.rawValue, attributes: fromHighlightDict))
        str.append(NSAttributedString(string: " ", attributes: normalDict))
        str.append(NSAttributedString(string: "to".localized, attributes: normalDict))
        str.append(NSAttributedString(string: " ", attributes: normalDict))
        str.append(NSAttributedString(string: toNetwork.rawValue, attributes: toHighlightDict))
        return AttributedString(str)
    }
    
    init(fromNetwork: LocalUserDefaults.FlowNetworkType, toNetwork: LocalUserDefaults.FlowNetworkType) {
        self.fromNetwork = fromNetwork
        self.toNetwork = toNetwork
    }
    
    func switchAction() {
        HUD.loading()
        WalletManager.shared.changeNetwork(toNetwork)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            HUD.dismissLoading()
            Router.dismiss()
        }
    }
}

struct NetworkSwitchPopView: View {
    @StateObject private var vm: NetworkSwitchPopViewModel
    
    init(from: LocalUserDefaults.FlowNetworkType, to: LocalUserDefaults.FlowNetworkType) {
        _vm = StateObject(wrappedValue: NetworkSwitchPopViewModel(fromNetwork: from, toNetwork: to))
    }
    
    var body: some View {
        VStack {
            SheetHeaderView(title: "switch_network_tips_title".localized)
            
            Text(vm.descString)
                .font(.inter(size: 14, weight: .regular))
                .foregroundColor(Color.LL.Neutrals.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            Spacer()
            
            fromToView
                .padding(.horizontal, 20)
            
            Spacer()
            
            buttonView
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
        .backgroundFill(Color.LL.Neutrals.background)
    }
    
    var fromToView: some View {
        ZStack {
            HStack {
                TargetView(color: vm.fromNetwork.color, name: vm.fromNetwork.rawValue.capitalized)
                Spacer()
                TargetView(color: vm.toNetwork.color, name: vm.toNetwork.rawValue.capitalized)
            }
            
            ChildAccountLinkView.ProcessingIndicator(state: .processing)
                .padding(.bottom, 20)
        }
    }
    
    var buttonView: some View {
        Button {
            vm.switchAction()
        } label: {
            Text("switch_network".localized)
                .foregroundColor(Color.LL.Button.text)
                .font(.inter(size: 14, weight: .bold))
                .frame(height: 54)
                .frame(maxWidth: .infinity)
                .background(Color.LL.Button.color)
                .cornerRadius(12)
        }
    }
}

extension NetworkSwitchPopView {
    struct TargetView: View {
        @State var color: Color
        @State var name: String
        
        var body: some View {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .frame(width: 64, height: 64)
                        .foregroundColor(color)
                    
                    Image(systemName: String.wifi)
                        .foregroundColor(.white)
                        .font(.inter(size: 25, weight: .medium))
                }
                
                Text(name)
                    .font(.inter(size: 12, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .lineLimit(1)
            }
            .frame(width: 130)
        }
    }
}
