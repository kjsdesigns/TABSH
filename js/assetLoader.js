/**
 * assetLoader.js
 * 
 * Provides a unified function to load background and enemy images.
 */

function preloadImage(src) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.src = src;
      img.onload = () => resolve(img);
      img.onerror = reject;
    });
  }
  
  /**
   * loadAllAssets(enemyTypes, backgroundSrc)
   * - enemyTypes: array of objects [{ name, src }, ...]
   * - backgroundSrc: string path to background image
   * 
   * Returns { loadedEnemies, loadedBackground }
   */
  export async function loadAllAssets(enemyTypes, backgroundSrc) {
    // 1) Preload background
    const bgPromise = preloadImage(backgroundSrc);
  
    // 2) Preload each enemy
    const enemyPromises = enemyTypes.map(async (type) => {
      const img = await preloadImage(type.src);
      const maxDim = 30;
      const scale = maxDim / Math.max(img.naturalWidth, img.naturalHeight);
      const w = Math.round(img.naturalWidth * scale);
      const h = Math.round(img.naturalHeight * scale);
      return {
        ...type,
        image: img,
        width: w,
        height: h,
        speed: 40,
      };
    });
  
    // Wait for everything
    const [loadedBackground, ...loadedEnemies] = await Promise.all([
      bgPromise,
      ...enemyPromises,
    ]);
  
    return {
      loadedEnemies,
      loadedBackground,
    };
  }