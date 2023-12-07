# Modified xv6 Documentation

## Introduction

This documentation provides an overview of the modifications made to the xv6 operating system, including new features and system calls. The enhancements aim to improve the scheduling policy, introduce copy-on-write functionality forking, and implement signal handling mechanisms.

## New Features

### Schedulers

#### Round Robin Scheduler

The Round Robin scheduler has been implemented to ensure fair allocation of CPU time among processes. Each process is assigned a fixed time quantum, and when the quantum expires, the scheduler switches to the next process in the queue.

#### Multi-Level Feedback Queue Scheduler

The Multi-Level Feedback Queue scheduler is designed to adapt to the behavior of processes over time. Processes are initially placed in a queue with a high time quantum, and based on their CPU usage, they are moved to different queues with varying time quanta.

#### First Come First Serve Scheduler

The First Come First Serve scheduler prioritizes processes based on their arrival time. The process that arrives first is given CPU time before others, ensuring a straightforward and predictable scheduling policy.

### Copy-on-Write Fork

The copy-on-write fork mechanism has been added to optimize the process forking operation. Instead of duplicating the entire process's memory space immediately, the parent and child processes initially share the same memory pages. Only when a process attempts to modify a shared page does the system create a separate copy for that process.

### Signal Handling

#### sigalarm

The `sigalarm` feature allows processes to set an alarm signal that will be delivered to the process after a specified time interval. This enables processes to schedule tasks or perform actions when a particular time duration elapses.

#### sigreturn

The `sigreturn` system call allows a process to restore its signal mask and register values to a previously saved state. This is useful in signal handling to ensure a clean and consistent restoration of the process's context.

### System Calls

#### getreadcount

The `getreadcount` system call provides a way for processes to inquire about the number of read system calls made by a given file descriptor. This information can be useful for monitoring and debugging purposes.

## Building and Running

To build and run the modified xv6 operating system, follow the standard xv6 build and execution procedures. Refer to the original xv6 documentation for detailed instructions.

```bash
make
make qemu scheduler = 'MLFQ(or)RR(or)FCFS'
```

## Conclusion

These modifications enhance the xv6 operating system by introducing new scheduling policies, optimizing process forking, and adding signal handling capabilities. Developers and users can take advantage of these features to create more efficient and responsive systems.
