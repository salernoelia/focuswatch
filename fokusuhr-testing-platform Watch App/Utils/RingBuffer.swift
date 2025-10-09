import Foundation

public class RingBuffer<T> {
  // MARK: - Private Properties

  /// The underlying array that stores the buffer elements. It's an array of optionals.
  private var buffer: [T?]

  /// The index of the oldest element in the buffer.
  private var head: Int = 0

  /// The index where the next new element will be inserted.
  private var tail: Int = 0

  /// The current number of elements in the buffer.
  private var count: Int = 0

  /// The maximum number of elements the buffer can hold.
  private let capacity: Int

  /// A concurrent dispatch queue with a barrier to ensure thread-safe read/write operations.
  private let queue = DispatchQueue(label: "ringbuffer.queue", attributes: .concurrent)

  // MARK: - Initializer

  /// Initializes the ring buffer with a specific capacity.
  /// - Parameter capacity: The maximum number of elements the buffer can store.
  public init(capacity: Int) {
    self.capacity = capacity
    self.buffer = Array(repeating: nil, count: capacity)
  }

  // MARK: - Public Methods

  /// Appends a new element to the buffer, overwriting the oldest element if the buffer is full.
  /// This operation is performed asynchronously and is thread-safe.
  /// - Parameter element: The element to add to the buffer.
  public func append(_ element: T) {
    // Use a barrier to ensure this write operation is exclusive.
    queue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      self.buffer[self.tail] = element
      // Move the tail to the next position, wrapping around if necessary.
      self.tail = (self.tail + 1) % self.capacity

      if self.count == self.capacity {
        // If the buffer is full, the head also moves, effectively dropping the oldest element.
        self.head = (self.head + 1) % self.capacity
      } else {
        // If the buffer is not yet full, just increment the count.
        self.count += 1
      }
    }
  }

  /// Returns a new array containing all the elements in the buffer, from oldest to newest.
  /// This operation is performed synchronously and is thread-safe.
  /// - Returns: An array of elements of type `T`.
  public func toArray() -> [T] {
    // Use sync to wait for the read operation to complete and return the value.
    return queue.sync {
      var result: [T] = []
      result.reserveCapacity(self.count)
      for i in 0..<self.count {
        let index = (self.head + i) % self.capacity
        if let element = self.buffer[index] {
          result.append(element)
        }
      }
      return result
    }
  }

  /// Returns the last `n` elements from the buffer.
  /// This operation is performed synchronously and is thread-safe.
  /// - Parameter n: The number of recent elements to retrieve.
  /// - Returns: An array containing the last `n` elements.
  public func last(_ n: Int) -> [T] {
    return queue.sync {
      var result: [T] = []
      let numberToFetch = min(n, self.count)
      result.reserveCapacity(numberToFetch)

      let start = self.count - numberToFetch
      for i in start..<self.count {
        let index = (self.head + i) % self.capacity
        if let element = self.buffer[index] {
          result.append(element)
        }
      }
      return result
    }
  }
}
