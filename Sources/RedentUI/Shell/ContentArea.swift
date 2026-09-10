import RedentDesign
import SwiftUI

/// The page itself, plus everything that hovers over it. The card it sits in
/// is drawn by the window, because the toolbar row shares that same surface.
///
/// Only what is on screen is kept in the view tree — rendering hidden web views
/// is what makes other browsers cost a gigabyte at twenty tabs. A split window
/// shows two, and no more.
struct ContentArea: View {
    @Bindable var model: BrowserModel

    var body: some View {
        SplitPageHost(model: model)
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            VStack(spacing: Metric.gutter) {
                PasswordSaveBar(model: model)
                PasswordFillButton(model: model)
            }
            .padding(.top, Metric.gutter + Metric.pageInset)
            .animation(.spring(duration: 0.3), value: model.autofill.pendingSave?.id)
            .animation(.spring(duration: 0.3), value: model.autofill.shouldOfferFill)
        }
        .overlay(alignment: .topTrailing) {
            if model.chrome.isFindBarVisible {
                FindBar(model: model)
                    .padding(.top, Metric.gutter + Metric.pageInset)
                    .padding(.trailing, Metric.gutter)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.26), value: model.chrome.isFindBarVisible)
        .overlay(alignment: .bottom) {
            OTPFloatingButton(model: model)
                .padding(.bottom, Metric.gutter + Metric.pageInset)
                .animation(.spring(duration: 0.32), value: model.otp.primary?.id)
        }
    }
}
