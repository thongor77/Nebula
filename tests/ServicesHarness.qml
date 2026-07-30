import QtQuick
import "../core/services"
import "mocks"

// Non-visual harness: instantiates all four Core services with mock
// adapters and exercises them, proving the Service/Adapter chain works
// with zero SDDM dependency (see docs/Services-Architecture.md). Run
// with `qml6 tests/ServicesHarness.qml` and read the console output —
// nothing is rendered on screen.
Item {
    id: root

    NebulaUserService {
        id: userService
        adapter: MockUserAdapter {}
    }

    NebulaSessionService {
        id: sessionService
        adapter: MockSessionAdapter {}
    }

    NebulaPowerService {
        id: powerService
        adapter: MockPowerAdapter {}
    }

    NebulaAuthService {
        id: authService
        adapter: MockAuthAdapter {}

        onSucceeded: console.log("ServicesHarness: authentication succeeded")
        onFailed: (reason) => console.log("ServicesHarness: authentication failed —", reason)
    }

    Component.onCompleted: {
        console.log("=== NebulaUserService ===")
        console.log("currentUser:", JSON.stringify(userService.currentUser))
        console.log("users.length:", userService.users.length)

        console.log("=== NebulaSessionService ===")
        console.log("sessions.length:", sessionService.sessions.length)
        console.log("currentIndex before:", sessionService.currentIndex)
        sessionService.selectSession(1)
        console.log("currentIndex after selectSession(1):", sessionService.currentIndex)

        console.log("=== NebulaPowerService ===")
        console.log("canShutdown:", powerService.canShutdown,
            "canReboot:", powerService.canReboot,
            "canSuspend:", powerService.canSuspend)

        console.log("=== NebulaAuthService ===")
        console.log("authenticating before:", authService.authenticating)
        authService.authenticate("nebula", "fake-password")
        console.log("authenticating right after call (async, still true):", authService.authenticating)
    }
}
