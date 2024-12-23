/**
 * dataManager.js
 * 
 * Provides a function to load data from a Google Sheet.
 */

// Example function to fetch and parse data from a Google Sheets range.
export async function loadSheetData(sheetId, apiKey, range) {
    // Construct the Sheets API URL
    const url = `https://sheets.googleapis.com/v4/spreadsheets/${sheetId}/values/${range}?key=${apiKey}`;
  
    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
  
      // Parse JSON returned by the Sheets API
      const json = await response.json();
  
      // The data is typically stored in json.values as a 2D array
      // Example: [["Name","Damage","Range"],["Archer Tower","10","150"]...]
      const rows = json.values;
      if (!rows || rows.length < 2) {
        // If no data or only a header row, return an empty array
        return [];
      }
  
      const headers = rows[0];
      const data = rows.slice(1).map((row) => {
        const obj = {};
        headers.forEach((header, i) => {
          // If a cell is missing, default to empty string
          obj[header] = row[i] !== undefined ? row[i] : "";
        });
        return obj;
      });
  
      return data;
    } catch (err) {
      console.error("Error fetching or parsing Sheets data:", err);
      return [];
    }
  }