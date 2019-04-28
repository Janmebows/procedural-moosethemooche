A group project with contributors:
Andrew Martin, James Schoff, Thomas Carey
The result of an Applied Probability assignment. Generating a jazz solo using discrete markovian methods based on the song Moose the Mooche by Charlie Parker.


The scripting is all in matlab.

Using the musicxml_parser and MIDI_Tools packages
Approach1 - Only concerned with the solo note transitions. This method is naive and will never really sound particularly good (notes do not resolve with chords 100% of the time).

Approach2 - Considers note/chord pairings and generates the combinations. This method would require some cleaning to be effective (i.e. removing some repetition of chords, etc.).This could be used to write a new pice, with a corresponding solo.

Approach3 - Considers note/chord pairings and only generates notes over the given chord backing. This approach would be to write a new solo over the same song.


EHT.m calculates the expected hitting time for the note, k conditioned on starting at i. i.e. the time until the note k is played.

EHT.m MUST be run after one of the other scripts.