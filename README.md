Schedulers implemented in this version of xv6 : 
  
<h1>Round Robin Scheduler(RR) - </h1>
 This is the default scheduler of the xv6 developed by MIT. This runs each process for a single clock tick after which it gives back control to any process which is available(RUNNABLE) by looking it up inside the proc table from the scheduler(); function in kernel/proc.c . 
  
<h1>First Come First Serve(FCFS) -  </h1>
This scheduler schedules process based on their arrival time. The process which arrives first gets CPU for it's entire running time. 
So the usertrap() function in kernel/trap.c doesn't call yield() during clock interrupt. In the scheduler() of kernel/proc.c we look for a runnable process with lowest arrival time.We then schedule that process for it's entire duration 
  
 <h1>Multi - Level Feedback Queue(MLFQ) - </h1>
 This scheduler create a Multi Level feedback Queue(MLFQ) data structure which consists of 4 queues with corresponding time slices: 
 <ul>
 <li> Queue 0 - 1 Tick </li>
 <li> Queue 1 - 3 Ticks </li>
 <li> Queue 2 - 9 Ticks </li>
 <li> Queue 3 - 15 Ticks </li>
 </ul>
Each process undergoes RoundRobin in it's respective Queue and after consuming it's time interval for Round Robin if it has not completed it is pushed down in a queue of one priority lower. The scheduler in kernel/proc.c checks for highest priority queue with highest waittime where waittime is the time it has not used CPU for. If a process does not get CPU for a certain number of ticks (here 30) we boost it's priority by 1 level to prevent starvation of process.  

<h2>Implementation</h2>
<ul>
  <li>We maintain 3 variables in struct proc in kernel/proc.h ie p->ticks_used , p->queue_no , p->waittime.</li>
  <li>This implementation does not require maintaing actual queues. It exploits waittime of processes to schedule them accordingly.</li>
  <li>The RUNNABLE process with highest queue priority is scheduled first. In case of same priority , the process with higher waittime is scheduled</li>
  <li>Waittime is initialised as 0 in allocproc() in kernel/proc.c</li>
  <li>In updatetime() of kernel/proc.c we increment waittime of all runnable processes by 1 and ticks_used of RUNNING process by one</li>
  <li>When a process is scheduled we reset waittime to 0.</li>
  <li>In usertrap of kernel/trap.c if a process exceeds the timeslice of queue , we demote the queue and reset ticks_used to 0</li>
  <li>In scheduler() in kernel/proc.c we first check runnable processes with waittime more than AGETICK (here 30) , we increase their priority by 1 .</li>
</ul>

 Results on running SCHEDULERTEST on the three algorithms: 
 <ul>
 <li>RR - Average rtime 11,  wtime 145 </li>
<li> FCFS - Average rtime 11,  wtime 122 </li>
 <li>MLFQ - Average rtime 9,  wtime 141 </li>
 </ul>
 ![image](https://github.com/serc-courses/mini-project-2-divyanash911/assets/114301176/606a3cfa-4b64-4023-b3a2-e5969758b645)
![image](https://github.com/serc-courses/mini-project-2-divyanash911/assets/114301176/9b5353ca-8dcf-45d0-9604-b145ae3db483)
