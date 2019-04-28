%find(chords(:,1)==starttime , 1,'last')

load('D:\Documents\Uni\2018\App Prob\Group Project\Song Data\Output.mat');    
notes= all_songs.raw_merged_nmat;
chords = getmidich(notes,1);

chordspace = generatechordspace(chords)






function chordspace = generatechordspace(chords)
%generates a matrix containing the chords in the song 
%matrix will contain rows n1, n2, n3, n4, index
%where ni is the ith note, and n4 = 0 means there is no 4th note
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
        error("Indexing is broke");
    end
end
startindex = endindex + 1;
end
end

function contains = matrixcontainsvector(matrix,vector)
%checks if a matrix of size (nxm) contains a vector of size(1xm)
[n,~] = size(matrix);
for j=1:n
    if isequal(matrix(j,:),vector)
        contains = 1;
        return;
    end

end
contains=0;
end