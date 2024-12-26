export const level2Data = {
  // For now, same background as level1
  background: "assets/maps/level1.png",
  mapWidth: 3530,
  mapHeight: 2365,
  path: [
    { x: 420,  y: 0    },
    { x: 800,  y: 860  },
    { x: 1300, y: 1550 },
    { x: 1500, y: 1750 },
    { x: 1950, y: 1920 },
    { x: 3530, y: 1360 },
  ],
  towerSpots: [
    { x: 1020, y: 660  },
    { x: 620,  y: 1280 },
    { x: 1340, y: 1080 },
    { x: 1020, y: 1660 },
    { x: 1800, y: 1560 },
    { x: 2080, y: 2150 },
    { x: 3250, y: 1150 },
  ],
  waves: [
    // We’ll just replicate the same wave definitions for demonstration
    {
      enemyGroups: [
        { type: "drone", count: 5, spawnInterval: 800, hpMultiplier: 1.0 },
      ],
    },
    {
      enemyGroups: [
        { type: "drone", count: 3, spawnInterval: 700, hpMultiplier: 1.1 },
        { type: "leaf_blower", count: 2, spawnInterval: 1200, hpMultiplier: 1.1 },
      ],
    },
    {
      enemyGroups: [
        { type: "leaf_blower", count: 4, spawnInterval: 1000, hpMultiplier: 1.2 },
        { type: "drone", count: 3, spawnInterval: 700, hpMultiplier: 1.2 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_digger", count: 4, spawnInterval: 900, hpMultiplier: 1.3 },
        { type: "drone", count: 4, spawnInterval: 600, hpMultiplier: 1.3 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_digger", count: 5, spawnInterval: 800, hpMultiplier: 1.4 },
        { type: "leaf_blower", count: 4, spawnInterval: 1200, hpMultiplier: 1.4 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_walker", count: 3, spawnInterval: 1200, hpMultiplier: 1.5 },
        { type: "drone", count: 4, spawnInterval: 600, hpMultiplier: 1.5 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_walker", count: 4, spawnInterval: 1200, hpMultiplier: 1.6 },
        { type: "leaf_blower", count: 3, spawnInterval: 900, hpMultiplier: 1.6 },
      ],
    },
    {
      enemyGroups: [
        { type: "drone", count: 6, spawnInterval: 600, hpMultiplier: 1.7 },
        { type: "leaf_blower", count: 4, spawnInterval: 900, hpMultiplier: 1.7 },
        { type: "trench_digger", count: 2, spawnInterval: 800, hpMultiplier: 1.7 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_digger", count: 5, spawnInterval: 700, hpMultiplier: 1.8 },
        { type: "trench_walker", count: 3, spawnInterval: 1300, hpMultiplier: 1.8 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_walker", count: 6, spawnInterval: 1000, hpMultiplier: 1.9 },
        { type: "leaf_blower", count: 5, spawnInterval: 1000, hpMultiplier: 1.9 },
      ],
    },
  ],
};
