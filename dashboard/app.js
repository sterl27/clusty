const state = {
  paused: false,
  search: '',
  data: {
    cluster: {
      health: 99.2,
      activeAgents: 8,
      agentsDelta: 2,
      gpuUtilization: 64,
      gpuMemUsedGiB: 8.5,
      gpuMemTotalGiB: 12,
      throughputGbps: 6.4,
      droppedPackets: 12,
    },
    agents: [],
    nodes: [],
    gpus: [],
    network: [],
    alerts: [],
  },
};

const el = {
  feedStatus: document.getElementById('feedStatus'),
  feedMeta: document.getElementById('feedMeta'),
  pauseBtn: document.getElementById('pauseBtn'),
  searchInput: document.getElementById('searchInput'),
  clusterHealth: document.getElementById('clusterHealth'),
  activeAgents: document.getElementById('activeAgents'),
  agentsDelta: document.getElementById('agentsDelta'),
  gpuUtil: document.getElementById('gpuUtil'),
  gpuMem: document.getElementById('gpuMem'),
  netThroughput: document.getElementById('netThroughput'),
  netErr: document.getElementById('netErr'),
  agentsTable: document.getElementById('agentsTable'),
  nodeCards: document.getElementById('nodeCards'),
  gpuBars: document.getElementById('gpuBars'),
  networkTable: document.getElementById('networkTable'),
  alertList: document.getElementById('alertList'),
  agentCountTag: document.getElementById('agentCountTag'),
  nodeCountTag: document.getElementById('nodeCountTag'),
  gpuCountTag: document.getElementById('gpuCountTag'),
  alertCountTag: document.getElementById('alertCountTag'),
};

const rand = (min, max) => Math.random() * (max - min) + min;
const randInt = (min, max) => Math.floor(rand(min, max + 1));

function statusClass(status) {
  if (status === 'healthy') return 'healthy';
  if (status === 'degraded') return 'degraded';
  return 'offline';
}

function makeSeedData() {
  state.data.nodes = [
    { name: 'ctrl-01', role: 'control-plane', cpu: 52, mem: 63, pods: 37, status: 'healthy', zone: 'edge-a' },
    { name: 'gpu-node', role: 'worker-gpu', cpu: 71, mem: 74, pods: 18, status: 'healthy', zone: 'edge-a' },
    { name: 'worker-02', role: 'worker', cpu: 44, mem: 57, pods: 29, status: 'healthy', zone: 'edge-b' },
    { name: 'worker-03', role: 'worker', cpu: 61, mem: 66, pods: 31, status: 'degraded', zone: 'edge-b' },
  ];

  state.data.agents = [
    { id: 'oc-orch-1', role: 'orchestrator', node: 'ctrl-01', status: 'healthy', latency: 22, cpu: 35 },
    { id: 'oc-scout-2', role: 'collector', node: 'worker-02', status: 'healthy', latency: 28, cpu: 22 },
    { id: 'oc-gpu-vision', role: 'inference', node: 'gpu-node', status: 'healthy', latency: 19, cpu: 58 },
    { id: 'oc-netguard', role: 'network-watch', node: 'worker-03', status: 'degraded', latency: 76, cpu: 49 },
    { id: 'oc-ops-eye', role: 'diagnostics', node: 'ctrl-01', status: 'healthy', latency: 24, cpu: 31 },
    { id: 'oc-route-ml', role: 'planner', node: 'worker-03', status: 'healthy', latency: 34, cpu: 26 },
    { id: 'oc-chaos-sim', role: 'simulator', node: 'worker-02', status: 'healthy', latency: 29, cpu: 42 },
    { id: 'oc-alert-hub', role: 'alerting', node: 'ctrl-01', status: 'healthy', latency: 17, cpu: 20 },
  ];

  state.data.gpus = [
    { id: 'RTX-4070-0', node: 'gpu-node', util: 64, memUsed: 8.5, memTotal: 12, temp: 67 },
  ];

  state.data.network = [
    { path: 'ctrl-01 ↔ gpu-node', rttMs: 2.4, throughputGbps: 8.6, lossPct: 0.02 },
    { path: 'ctrl-01 ↔ worker-02', rttMs: 3.0, throughputGbps: 7.8, lossPct: 0.05 },
    { path: 'ctrl-01 ↔ worker-03', rttMs: 5.7, throughputGbps: 5.1, lossPct: 0.44 },
    { path: 'gpu-node ↔ worker-03', rttMs: 6.8, throughputGbps: 4.2, lossPct: 0.61 },
  ];

  state.data.alerts = [
    {
      level: 'critical',
      title: 'Node worker-03 packet loss spike',
      detail: 'Sustained packet loss >0.5% for 3m',
      time: 'just now',
    },
    {
      level: 'warning',
      title: 'GPU thermal trend rising',
      detail: 'RTX-4070-0 at 67°C (threshold 72°C)',
      time: '14s ago',
    },
  ];
}

function tickMockData() {
  const cluster = state.data.cluster;
  cluster.health = Math.max(93, Math.min(100, cluster.health + rand(-0.25, 0.25)));

  state.data.nodes.forEach((node) => {
    node.cpu = Math.max(8, Math.min(98, node.cpu + rand(-5, 5)));
    node.mem = Math.max(15, Math.min(96, node.mem + rand(-3, 3)));
    node.pods = Math.max(8, Math.min(50, node.pods + randInt(-2, 2)));
    if (Math.random() < 0.03) {
      node.status = node.status === 'healthy' ? 'degraded' : 'healthy';
    }
  });

  state.data.agents.forEach((agent) => {
    agent.latency = Math.max(8, Math.min(150, agent.latency + randInt(-7, 8)));
    agent.cpu = Math.max(3, Math.min(96, agent.cpu + randInt(-6, 6)));
    if (Math.random() < 0.02) {
      agent.status = ['healthy', 'degraded'][randInt(0, 1)];
    }
  });

  state.data.gpus.forEach((gpu) => {
    gpu.util = Math.max(12, Math.min(99, gpu.util + randInt(-9, 9)));
    gpu.memUsed = Math.max(2, Math.min(gpu.memTotal, +(gpu.memUsed + rand(-0.9, 0.9)).toFixed(1)));
    gpu.temp = Math.max(44, Math.min(82, gpu.temp + randInt(-2, 3)));
  });

  state.data.network.forEach((n) => {
    n.rttMs = Math.max(1, +(n.rttMs + rand(-0.5, 0.8)).toFixed(1));
    n.throughputGbps = Math.max(1.4, +(n.throughputGbps + rand(-0.9, 0.7)).toFixed(1));
    n.lossPct = Math.max(0.01, +(n.lossPct + rand(-0.08, 0.1)).toFixed(2));
  });

  cluster.activeAgents = state.data.agents.filter((a) => a.status !== 'offline').length;
  cluster.agentsDelta = randInt(-2, 4);
  cluster.gpuUtilization = Math.round(state.data.gpus.reduce((acc, g) => acc + g.util, 0) / state.data.gpus.length);
  cluster.gpuMemUsedGiB = +state.data.gpus.reduce((acc, g) => acc + g.memUsed, 0).toFixed(1);
  cluster.gpuMemTotalGiB = state.data.gpus.reduce((acc, g) => acc + g.memTotal, 0);
  cluster.throughputGbps = +(state.data.network.reduce((acc, n) => acc + n.throughputGbps, 0) / state.data.network.length).toFixed(1);
  cluster.droppedPackets = randInt(0, 25);

  const occasionallyAlert = Math.random() < 0.18;
  if (occasionallyAlert) {
    const levels = ['warning', 'critical'];
    const level = levels[randInt(0, 1)];
    state.data.alerts.unshift({
      level,
      title: level === 'critical' ? 'Agent quorum instability' : 'Inference queue backlog',
      detail:
        level === 'critical'
          ? 'Consensus heartbeat jitter beyond safe threshold.'
          : 'Queue depth above target for 30s on gpu-node.',
      time: 'just now',
    });
    state.data.alerts = state.data.alerts.slice(0, 10);
  }
}

function render() {
  const { cluster, agents, nodes, gpus, network, alerts } = state.data;
  const q = state.search.trim().toLowerCase();

  el.clusterHealth.textContent = `${cluster.health.toFixed(1)}%`;
  el.activeAgents.textContent = `${cluster.activeAgents}`;
  el.agentsDelta.textContent = `${cluster.agentsDelta >= 0 ? '+' : ''}${cluster.agentsDelta} in 1m`;
  el.gpuUtil.textContent = `${cluster.gpuUtilization}%`;
  el.gpuMem.textContent = `${cluster.gpuMemUsedGiB} / ${cluster.gpuMemTotalGiB} GiB`;
  el.netThroughput.textContent = `${cluster.throughputGbps} Gbps`;
  el.netErr.textContent = `${cluster.droppedPackets} dropped packets`;

  const filteredAgents = q
    ? agents.filter((a) => `${a.id} ${a.role} ${a.node}`.toLowerCase().includes(q))
    : agents;

  el.agentCountTag.textContent = `${agents.length} total`;
  el.agentsTable.innerHTML = filteredAgents
    .map(
      (a) => `
      <tr>
        <td>${a.id}</td>
        <td>${a.role}</td>
        <td>${a.node}</td>
        <td class="status ${statusClass(a.status)}">${a.status}</td>
        <td>${a.latency} ms</td>
        <td>${a.cpu}%</td>
      </tr>`
    )
    .join('');

  const filteredNodes = q
    ? nodes.filter((n) => `${n.name} ${n.role} ${n.zone}`.toLowerCase().includes(q))
    : nodes;

  el.nodeCountTag.textContent = `${nodes.length} nodes`;
  el.nodeCards.innerHTML = filteredNodes
    .map(
      (n) => `
      <div class="node-card">
        <h4>${n.name}</h4>
        <div class="node-meta">${n.role} • ${n.zone}</div>
        <div class="tiny">CPU ${Math.round(n.cpu)}% • MEM ${Math.round(n.mem)}% • PODS ${n.pods}</div>
        <div class="status ${statusClass(n.status)}">${n.status}</div>
      </div>`
    )
    .join('');

  el.gpuCountTag.textContent = `${gpus.length} GPU(s)`;
  el.gpuBars.innerHTML = gpus
    .map(
      (g) => `
      <div class="gpu-row">
        <div>${g.id}<div class="tiny">${g.node} • ${g.temp}°C</div></div>
        <div class="bar"><span style="width:${g.util}%"></span></div>
        <div>${g.util}%</div>
      </div>
      <div class="tiny">Memory: ${g.memUsed} / ${g.memTotal} GiB</div>`
    )
    .join('');

  el.networkTag.textContent = `${network.length} links`;
  el.networkTable.innerHTML = network
    .map(
      (n) => `
      <tr>
        <td>${n.path}</td>
        <td>${n.rttMs} ms</td>
        <td>${n.throughputGbps} Gbps</td>
        <td>${n.lossPct}%</td>
      </tr>`
    )
    .join('');

  const openAlerts = alerts.length;
  el.alertCountTag.textContent = `${openAlerts} open`;
  el.alertList.innerHTML = alerts
    .map(
      (a) => `
      <li class="alert-item alert-${a.level}">
        <strong>${a.title}</strong>
        <div>${a.detail}</div>
        <small>${a.time}</small>
      </li>`
    )
    .join('');
}

function setPausedUI(paused) {
  if (paused) {
    el.feedStatus.textContent = 'PAUSED';
    el.feedStatus.classList.remove('pill-live');
    el.feedStatus.classList.add('pill-paused');
    el.pauseBtn.textContent = 'Resume Stream';
    return;
  }
  el.feedStatus.textContent = 'LIVE';
  el.feedStatus.classList.remove('pill-paused');
  el.feedStatus.classList.add('pill-live');
  el.pauseBtn.textContent = 'Pause Stream';
}

function wireEvents() {
  el.pauseBtn.addEventListener('click', () => {
    state.paused = !state.paused;
    setPausedUI(state.paused);
  });

  el.searchInput.addEventListener('input', (e) => {
    state.search = e.target.value;
    render();
  });
}

function connectRealtimeFeed() {
  // Optional: set window.OPENCLAW_WS_URL before loading the page.
  const wsUrl = window.OPENCLAW_WS_URL;
  if (!wsUrl) {
    el.feedMeta.textContent = 'Mock stream @ 1s';
    return;
  }

  try {
    const ws = new WebSocket(wsUrl);
    el.feedMeta.textContent = `Socket: ${wsUrl}`;

    ws.addEventListener('message', (event) => {
      if (state.paused) return;

      const payload = JSON.parse(event.data);
      // Expected shape: { cluster, agents, nodes, gpus, network, alerts }
      state.data = { ...state.data, ...payload };
      render();
    });

    ws.addEventListener('close', () => {
      el.feedMeta.textContent = 'Socket disconnected, using mock stream';
    });
  } catch (_err) {
    el.feedMeta.textContent = 'Socket failed, using mock stream';
  }
}

function start() {
  makeSeedData();
  wireEvents();
  connectRealtimeFeed();
  render();

  setInterval(() => {
    if (state.paused) return;
    tickMockData();
    render();
  }, 1000);
}

start();
