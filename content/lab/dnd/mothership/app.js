// Read the query parameters to determine the character.

function setup() {
    const urlParams = new URLSearchParams(window.location.search);
    const charKey = urlParams.get('c');

    if (!/^[a-z0-9_-]+$/i.test(charKey)) {
        throw new Error('Invalid character key');
      }

    const charSrc = `characters/${charKey}.json`;

    const charData = await fetch(charSrc)
      .then(r => {
        if (!r.ok) throw new Error('Not found');
        return r.json();
      });

    // If not in database, load it from local storage.
    
    // Browse saved characters.
    'keys'
}

// Local storage functionality for character sheets.
// Allow us to alter stats, take notes, etc., all by character.
// Save to local storage after every change.

// Save status

// Characer name

// Character ID
// Check if it exists in the database. If not, create it. If it does, warn the
// user that it already exists.

// High score

// Personal notes

// Multi-page journal.

// Editing stats

// Basic stats: strength, speed, intellect, combat

// Saves: sanity, fear, body

// Hover to see original values

// Stress
// Health
// Wounds

// Conditions

// Inventory

// Credits

// Armor points

// Skills
// Select skills
// Add skill
// Intentionally haven't implemented the prerequisite system. DnD is more flexible.
// Expect the players to make sure their skills are valid and approved by the DM.


if (document.readyState === 'loading') {
    document.addEventListener("DOMContentLoaded", () => {
        setup();
    });
} else {
    setup();
}