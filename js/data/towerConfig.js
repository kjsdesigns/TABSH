/**
 * towerConfig.js
 * 
 * We extracted the tower definitions from towerManager.js to reduce redundancy
 * and allow for easy extension or balancing of tower stats without changing logic code.
 */

export const TOWER_DEFINITIONS = [
  {
    type: "point",
    basePrice: 80,
    range: 169,
    splashRadius: 0,
    fireRate: 1.5 * 0.8, // originally 1.5, but we apply a 20% speed-up => 1.2
    upgrades: [
      { level: 1, damage: 10, upgradeCost: 0   },
      { level: 2, damage: 15, upgradeCost: 50  },
      { level: 3, damage: 20, upgradeCost: 100 },
      { level: 4, damage: 25, upgradeCost: 150 },
    ],
  },
  {
    type: "splash",
    basePrice: 80,
    range: 104,
    splashRadius: 50,
    fireRate: 1.5 * 0.8, // 1.2
    upgrades: [
      { level: 1, damage: 8,  upgradeCost: 0   },
      { level: 2, damage: 12, upgradeCost: 50  },
      { level: 3, damage: 16, upgradeCost: 100 },
      { level: 4, damage: 20, upgradeCost: 150 },
    ],
  },
];
