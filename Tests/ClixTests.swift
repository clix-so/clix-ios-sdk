import XCTest
@testable import Clix

final class ClixTests: XCTestCase {
  actor Counter {
    private var value = 0

    func increment() {
      value += 1
    }

    func currentValue() -> Int {
      value
    }
  }

  func testInitCoordinatorRunsSingleFlightOperationOnce() async {
    let coordinator = Clix.InitCoordinator()
    let counter = Counter()

    let firstTask = await coordinator.acquireInitializationTask {
      try? await Task.sleep(nanoseconds: 100_000_000)
      await counter.increment()
    }
    let secondTask = await coordinator.acquireInitializationTask {
      await counter.increment()
    }

    await firstTask.value
    await secondTask.value

    let value = await counter.currentValue()
    XCTAssertEqual(value, 1)
  }

  func testInitCoordinatorAllowsNewOperationAfterCompletion() async {
    let coordinator = Clix.InitCoordinator()
    let counter = Counter()

    let firstTask = await coordinator.acquireInitializationTask {
      await counter.increment()
    }
    await firstTask.value

    let secondTask = await coordinator.acquireInitializationTask {
      await counter.increment()
    }
    await secondTask.value

    let value = await counter.currentValue()
    XCTAssertEqual(value, 2)
  }
}
