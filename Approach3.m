%Code for App Prob Group project
%given a .mxml file, creates a note matrix,
%using the note matrix, generates procedual music based on random walks
%
%most sophisticated generation (of the 3)
%Considers note/chord pairings but only generates notes
%
%Dependent on the XML and MIDI toolkits
%May 2018
%Andrew Martin, James Schoff, Thomas Carey

%-----------------------------
%set the rng for reproducibility
s=rng(1704466);


%load the data from the mxml
load('D:\Documents\Uni\2018\App Prob\Group Project\Song Data\Output.mat');
notes= all_songs.raw_merged_nmat;

%separate chords and lead
chords = getmidich(notes,1);
lead = getmidich(notes,2);


%find all the chords
chordspace = generatechordspace(chords);

%the number of chords is equal to the last chords' index
numchords = chordspace(end,end);
%The range of all possible lead notes
rangeLeadNotes = range(lead(:,4)) + 1;
%Preallocate a 3d matrix of form:
%[current note, next note, chord played]
insidechordnotetransitions = zeros(rangeLeadNotes,rangeLeadNotes,numchords);

%Work out how the notes will get shifted
leadshift = min(lead(:,4)) - 1;
%shift the lead matrix so that things work
leadshifted = [lead(:,1:3) , lead(:,4)-leadshift , lead(:,5:end)];
%Replace the second column with end times rather than durations
%(This helps a bit later on)
leadshifted(:,2) = leadshifted(:,1) + leadshifted(:,2);
chordstimefixed = chords;
chordstimefixed(:,2) = chords(:,1)+chords(:,2);



%%Generating the Transition Probability Matrix
%---------------------------------------------
chordnoteindex =1;
%so that startindex gets the first note - set endindex=0
endindex=0;
index = 2;
oldnote = leadshifted(1,4);
while endindex<length(chords)
    %get the chord & start and end times
    startindex  = endindex+1;
    endindex    = find(chordstimefixed(:,1) == chordstimefixed(startindex,1),1,'last');
    starttime   = chordstimefixed(startindex,1);
    endtime     = chordstimefixed(endindex,2);
    %makes the chord
    notechordpair = zeros(1,4);
    notechordpair(1:endindex-startindex+1) = chordstimefixed(startindex:endindex,4)';
    
    %find the chord's index
    [~,chordnumber] =matrixcontainsvector(chordspace(:,1:end-1),notechordpair(1:end));
    

    %Goes through each lead note until the current chord ends
    while (index <=length(lead) &&leadshifted(index,2) < endtime)
        newnote = leadshifted(index,4);
        %increment the corresponding (i,j,c) index
        insidechordnotetransitions(oldnote,newnote,chordnumber) = insidechordnotetransitions(oldnote,newnote,chordnumber) +1;
        oldnote = newnote;
        index=index+1;
    end
end



%j corresponds to the chord index
%goes backwards for speed & preallocation
for j=numchords:-1:1
    dtmcarray(j) = dtmc(insidechordnotetransitions(:,:,j));
end

%%Simulating the random walk
%---------------------------
%we only care about the number of notes in lead here
lengthSolo= length(lead);

%initialise to the first time in the song
%(should consistently be 0 - unless there are mutes at the start!)
time = chordstimefixed(1,1);

%have to initialise the very first lead note randomly
%based on the obtainable notes of the first chord
%dtmcarray(1).P is the P matrix for the first chord
lastnote = jumptorandomstate(dtmcarray(1));

%find the time for the last note to start
lastnotestarttime = leadshifted(end,2);
chordendindex = 0;
%initialise the vector of new lead notes
leadnotes=zeros(1,length(lead));

%Iterate through the whole song
while time < lastnotestarttime
    %Find what chord is playing
    chordstartindex = find(chordstimefixed(:,1) == chordstimefixed(chordendindex+1,1),1,'first');
    chordendindex   = find(chordstimefixed(:,1) == chordstimefixed(chordstartindex,1),1,'last');
    chordstarttime  = chordstimefixed(chordstartindex,1);
    chordendtime    = chordstimefixed(chordendindex,2);
    %Get the current chord's index value
    currentchord = zeros(1,4);
    currentchord(1:chordendindex-chordstartindex+1) = chordstimefixed(chordstartindex:chordendindex,4);
    [~,chordindex] = matrixcontainsvector(chordspace(:,1:end-1),currentchord);
    
    %how many notes to simulate
    leadshiftedstartindex = find(leadshifted(:,1)>= chordstarttime,1,'first');
    leadshiftedendindex   = find(leadshifted(:,2) < chordendtime,1,'last');
    
    numLeadNotesInInterval = leadshiftedendindex-leadshiftedstartindex;
    if numLeadNotesInInterval<=0
        continue;
    end
    %simulate lead notes in that stretch
    %only want to simulate the path starting at lastnote
    
    %This decides on which note we start the simulation at
    initstate = zeros(1,rangeLeadNotes);
    initstate(lastnote) = 1;
    leadnotestoappend = jumpsimulate(dtmcarray(chordindex),numLeadNotesInInterval, initstate);
    leadnotes(leadshiftedstartindex:leadshiftedendindex) = leadnotestoappend;
    lastnote = leadnotestoappend(end);
    %go to next chord
    time=chordendtime;
end


leadshiftedback = leadnotes + leadshift;
lead(:,4) = leadshiftedback;
%concatenate the chords and lead
notematrix = [chords;lead];

%generate the midi!
writemidi(notematrix,"Process3.mid",all_songs.tempo_bpm);


function X = jumpsimulate(mc,numSteps,X0)
%Copy of the inbuilt matlab simulate
%this version however will - if an unobtainable state is obtained
%jump to a random state

P = mc.P;
numStates = mc.NumStates;

if isempty(X0) % Pick random initial state
    
    X0 = zeros(1,numStates);
    p = randperm(numStates,1);
    X0(p) = 1;
    
end

numSims = sum(X0);

X = zeros(1+numSteps,numSims);

for j = 1:numSims
    
    simState = find(X0~=0,1);
    X(1,j) = simState;
    
    X0(simState) = X0(simState)-1;
    
    for i = 2:(1+numSteps)
        
        u = rand;
        simState = find(u < cumsum(P(simState,:)),1);
        if isempty(simState)
            X(i,j) = jumptorandomstate(mc);
        else
            X(i,j) = simState;
        end
    end
    
end
end

function X = jumptorandomstate(mc)
%When a NaN only state is obtained this will
%shift the note into a state which is obtainable with the chord
temp = sum(mc.P,2);
temp = ~isnan(temp);
temp =find(temp,length(temp));
X = temp(randi(length(temp)));

end

function chordspace = generatechordspace(chords)
%generates a matrix containing the chords in the song
%matrix will contain rows n_1, n_2, n_3, n_4, index
%where n_i is the ith note, and n_4 = 0 means there is no 4th note
chordspace=[];
%index value for the chord
index =1;
%starting index for searching
startindex = 1;
%find the last note played with the same time
endindex=0;
while endindex < length(chords)
    endindex = find(chords(:,1)==chords(startindex,1), 1,'last');
    
    %if 3 note chord
    if (endindex - startindex) == 2
        chord = [chords(startindex:endindex,4)', 0,index];
        if ~matrixcontainsvector(chordspace(:,1:end-1),chord(1:end-1))
            chordspace = [chordspace;chord];
            index = index +1;
        end
    else
        %if 4 note chord
        if(endindex - startindex) ==3
            chord =[chords(startindex:endindex,4)',index];
            if ~matrixcontainsvector(chordspace(:,1:end-1),chord(1:end-1))
                chordspace = [chordspace;chord];
                index = index +1;
            end
        else
            error("There was an error generating the Chord State Space");
        end
    end
    startindex = endindex + 1;
end
end

function [contains ,index]= matrixcontainsvector(matrix,vector)
%checks if a matrix of size (nxm) contains a vector of size(1xm)
[n,~] = size(matrix);
for j=1:n
    if isequal(matrix(j,:),vector)
        contains = 1;
        index = j;
        return;
    end
    
end
contains=0;
index=0;
end