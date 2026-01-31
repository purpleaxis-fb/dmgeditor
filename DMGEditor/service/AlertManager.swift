import SwiftUI
import Combine

/// 用于在 SwiftUI 中唯一标识一个 Alert 的数据结构
struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

/// 一个全局的、可观察的服务，用于在应用中的任何地方触发 Alert
@MainActor
class AlertManager: ObservableObject {
    
    /// 当这个属性被设置时，绑定的 UI 会自动弹出 Alert
    @Published var alertInfo: AlertInfo?

    /// 在应用中的任何地方调用此方法来显示一个全局 Alert
    /// - Parameters:
    ///   - title: Alert 的标题
    ///   - message: Alert 的详细信息
    func showAlert(title: String, message: String) {
        self.alertInfo = AlertInfo(title: title, message: message)
    }
}
