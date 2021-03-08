import PlaygroundSupport
import UIKit

PlaygroundPage.current.needsIndefiniteExecution = true

// Tasks sent to Dispatch queues will always start tasks in the order they are dispatched (regardless of whether its a serial or concurrent queue)

// Serial queue completes each task before moving onto the next task
let serialQueue = DispatchQueue(label: "pangers.serial.queue")

serialQueue.async {
    print("Serial Task 1 started")
    // Some work
    print("Serial Task 1 finished")
}

serialQueue.async {
    print("Serial Task 2 started")
    // Some work
    print("Serial Task 2 finished")
}
// In the above, task 1 will be completed before task 2 starts

// Tasks sent to a concurrent queue will start in the order they are queued, but each successive task may begin before the previous task is finished. This means that the order each task is finished in not guaranteed.
// Single-core CPUs and Multi-core CPUs can both run tasks concurrently. In a single-core environment, the CPU will jump between tasks (before they are finished) to execute the tasks concurrently. The tasks don't run at the exact same instant in time.
// With multi-core CPUs, tasks can be run at the exact same instant in time since there are multiple cores available to perform work. This is called parallelism.
// Apple Documentation doesn't explicitly say where tasks dispatched on a concurrent queue will run in parallel (or just concurrently). That is probably abstracted away from us.
let concurrentQueue = DispatchQueue(label: "pangers.concurrent.queue", attributes: .concurrent)

concurrentQueue.async {
    print("Concurrent task 1 started")
    // Some work
    print("Concurrent task 1 finished")
}

concurrentQueue.async {
    print("Concurrent task 2 started")
    // Some work
    print("Concurrent task 2 finished")
}
// In the above, task 1 is started then task 2 is started. So both tasks have been started, then either task could complete first (up to the system to decide)


// Making thread safe objects
// If an object it accessed from different threads, there is a chance that a data race occurs. One thread could be reading from a value while another thread is updating the value at the same time
// For data race to occur one of the access has to be a write - if all accesses are a read, then there isn't a chance for the underlying data to be unsynchronized.
// Do we need to do this for all our objects? No, cause that would make things unnecessarily complex. We really have to think about whether there is a chance an object will be accessed from different threads, and if there is a good chance it will be, then this approach will be appropriate.
final class Messenger {
    private var messages: [String] = []
    
    // We want to use a concurrent queue so we can perform multiple accesses to this object at the same time, improving performance (eg. this object might be read from in multiple places in an app)
    // We could have used a serial queue, but then we would lose the ability to do multiple reads concurrently losing out on performance
    private var queue = DispatchQueue(label: "messages.concurrent.queue", attributes: .concurrent)
    
    var lastMessage: String? {
        // Reading data on the concurrent queue
        // Typically reads are `.sync` as you would want the value from the read immediately (we wouldn't expect the read to require a completion handler)
        return queue.sync {
            messages.last
        }
    }
    
    func postMessage(_ newMessage: String) {
        // Writing data on the concurrent queue
        // Barrier flag delays the task until all previously submitted tasks are finished executing. Once the last task is finished executing, the queue executes the barrier block (alone - no other tasks can begin). Once the barrier block completes, other tasks may be dispatched as usual.
        // It effectively turns the concurrent queue into a serial queue for one task
        // As we are writing to the data, we don't want anyone else to read from the data until we are done writing, hence the usage of the barrier flag
        // IF we used a serial queue, we wouldn't need the barrier flag (in fact .sync(flag:) doesn't even exist) because each task would be started and completed before the next start begins, meaning we wouldn't have any data races
        queue.async(flags: .barrier) {
            self.messages.append(newMessage)
        }
    }
}

// Choosing `.async` vs `.sync`
// Synchronously starting a task will block the calling thread until the task is finished
// Asynchronously starting a task will return to the calling thread without waiting for the task to finish
// You wouldn't want to use `.sync` from the main thread for a long running task otherwise you would block the UI
// When would you want to use one over the other?
// Think about the expected interface of the object in question. Would you expect to use a closure as an onCompletion handler to get the result? If so, maybe `.async` is a good choice. If you'd expect the result to be returned without a closure, you may want to use `.sync`.
// However, don't add too many blocking tasks (.sync) when the current thread is a concurrent queue. The system will create additional threads to run other queue concurrent tasks and if too many tasks block, the system may run out of thread for you app.
