//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// Concurrent Tasks

func longRunningTask1(completion: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3) {
        completion()
    }
}

func longRunningTask2(completion: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5) {
        completion()
    }
}

func nonAsyncTask(completion: @escaping () -> Void) {
    completion()
}

DispatchQueue.global(qos: .userInitiated).async {
    
    var tasksDone: [String] = []
    
    print("Starting long running tasks")
    
    let group = DispatchGroup()
    
    group.enter()
    print("Starting long running task 1")
    longRunningTask1 {
        print("Long running task 1 finished")
        tasksDone.append("Task1")
        group.leave()
    }
//    group.enter()
//    print("Starting non async task")
//    nonAsyncTask {
//        print("Non async task finished")
//        tasksDone.append("Non async task")
//        group.leave()
//        print("Group left for non async task")
//    }
    
    group.enter()
    print("Starting long running task 2")
    longRunningTask2 {
        print("Long running task 2 finished")
        tasksDone.append("Task2")
        group.leave()
        print("Group left for long running task 2")
    }
//    group.enter()
//    print("Starting non async task 2")
//    nonAsyncTask {
//        print("Non async task 2 finished")
//        tasksDone.append("Non async task 2")
//        group.leave()
//        print("Group left for non async task 2")
//    }
    
    print("Wait is hit")
    group.wait()
    
    print("The tasks done were: \(tasksDone)")
    
}


