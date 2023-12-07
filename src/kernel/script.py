import matplotlib.pyplot as plt

# Read data from the text file
data = []
with open('op.txt', 'r') as file:
    for line in file:
        pid, ticks, q_no = map(int, line.strip().split())
        data.append((pid, ticks, q_no))

# Separate data into separate lists for each PID
pids = {}
for pid, ticks, q_no in data:
    if pid not in pids:
        pids[pid] = {'ticks': [], 'queue': []}
    pids[pid]['ticks'].append(ticks)
    pids[pid]['queue'].append(q_no)

# Create the graph
for pid, pid_data in pids.items():
    plt.plot(pid_data['ticks'], pid_data['queue'], label=f'PID {pid}')

# Customize the graph
plt.xlabel('Ticks')
plt.ylabel('Queue No')
plt.title('Queue No vs. Ticks for Different PIDs')
plt.legend()
plt.grid(True)

# Show the graph or save it to a file
plt.show()