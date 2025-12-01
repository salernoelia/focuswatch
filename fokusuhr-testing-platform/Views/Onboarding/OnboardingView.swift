import SwiftUI

struct OnboardingView: View {
  @Binding var hasCompletedOnboarding: Bool
  @StateObject private var telemetryManager = TelemetryManager.shared
  @State private var currentPage = 0

  private let pages = [
    OnboardingPage(
      icon: "applewatch",
      title: "Willkommen bei FokusUhr",
      description:
        "Die App unterstützt dich dabei, besser mit Fokus-Schwierigkeiten umzugehen."
    ),

    OnboardingPage(
      icon: "photo.on.rectangle.angled",
      title: "Individuelle Checklisten",
      description:
        "Erstelle individuelle Checklisten, welche dabei helfen, Routineabläufe zu meistern."
    ),
    OnboardingPage(
      icon: "calendar",
      title: "Bleibe organisiert",
      description:
        "Plane Termine mit Erinnerungen, die dir helfen, dich besser zu konzentrieren."
    ),
    // OnboardingPage(
    //   icon: "checklist",
    //   title: "Fortschritt verfolgen",
    //   description: "Verwalte Checklisten und behalte deine täglichen Aufgaben im Blick."
    // ),

    OnboardingPage(
      icon: "ipod.and.applewatch",
      title: "Verbindung zur Watch",
      description:
        "Um die Verbindung mit der Watch herzustellen, müssen beide Apps (Companion App und Watch App) gleichzeitig geöffnet sein."
    ),

    OnboardingPage(
      icon: "chart.bar.fill",
      title: "Hilf FokusUhr sich weiter zu verbessern",
      description:
        "Erlaube die Erfassung von anonymen Nutzungsdaten, um die App im Rahmen unserer wissenschaftlichen Forschung zu verbessern. Die Einstellung lässt sich auch später in den Einstellungen ändern."
    ),
  ]

  var body: some View {
    VStack {
      TabView(selection: $currentPage) {
        ForEach(0..<pages.count, id: \.self) { index in
          VStack(spacing: 30) {
            Spacer()

            Image(systemName: pages[index].icon)
              .font(.system(size: 80))
              .foregroundColor(.accentColor)

            VStack(spacing: 16) {
              Text(pages[index].title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

              Text(pages[index].description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

              if index == pages.count - 1 {
                Toggle("Telemetrie zulassen", isOn: $telemetryManager.hasConsent)
                  .onAppear {
                    telemetryManager.hasConsent = true
                  }
                  .padding(.horizontal, 48)
                  .padding(.top, 20)
              }
            }

            Spacer()
          }
          .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .always))

      Button {
        if currentPage < pages.count - 1 {
          withAnimation {
            currentPage += 1
          }
        } else {
          hasCompletedOnboarding = true
        }
      } label: {
        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .cornerRadius(12)
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 40)
    }
  }
}

private struct OnboardingPage {
  let icon: String
  let title: String
  let description: String
}

#Preview {
  OnboardingView(hasCompletedOnboarding: .constant(false))
}
