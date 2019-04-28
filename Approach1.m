%Code for App Prob Group project
%given a .mxml file, creates a note matrix,
%using the note matrix, generates procedual music based on random walks

%This generates notes based on the probability to go from
%note i to note j
%independently of chords and timing.
%
%Dependent on the XML and MIDI toolkits
%May 2018
%Andrew Martin, James Schoff, Thomas Carey

%-----------------------------
%For reproducibility
s=rng(1705565);


%whether or not to generate the note matrices
%set to 0 if they are already made
generatenmats = 0;
if generatenmats
    process_xml_data;
else
    load('D:\Documents\Uni\2018\App Prob\Group Project\Song Data\Output.mat');
end
notes= all_songs.raw_merged_nmat;
chords = getmidich(notes,1);
lead = getmidich(notes,2);



%Generate the transition probability matrix
rangeLeadNotes = range(lead(:,4)) + 1;
leadshifted = lead- min(lead(:,4)) + 1; %this is the state space S
transprobmatrix = zeros(rangeLeadNotes);
%up to length-1, so that we don't consider the shift after the last note
%(as it is nonexistent)
for i=1:length(lead)-1
    transprobmatrix(leadshifted(i,4),leadshifted(i+1,4)) = transprobmatrix(leadshifted(i,4),leadshifted(i+1,4))+ 1;
end

%normalize so each row sums to 1
transprobmatrix = transprobmatrix ./ sum(transprobmatrix,2);
%Curious over condition number
condition = cond(transprobmatrix);
digitloss = log10(cond(transprobmatrix));

trans10steps = transprobmatrix^(10);
%will try making one with same note timing as the original
newSolo = lead;
[lengthSolo, ~] = size(newSolo);
%reproducability


%simulate a new solo
markovMatrix = dtmc(transprobmatrix);


%This shifts the notes so that they are back to the old values
newnotes = simulate(markovMatrix, lengthSolo-1) + min(lead(:,4))-1;
newSolo(:,4) = newnotes;

newSoloWithChords = [newSolo;chords];
%Generates the midi!
writemidi(newSoloWithChords,"Process1.mid",all_songs.tempo_bpm);

