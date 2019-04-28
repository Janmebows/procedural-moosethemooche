%will solve for the kth NONZERO note
approach2=0;
absorbprobmatrix = markovMatrix.P;
absorbprobmatrix(~any(absorbprobmatrix,2),:) =[];
absorbprobmatrix(:,~any(absorbprobmatrix,1)) =[];
numNotes = length(absorbprobmatrix);

K =sym ('k',[1,numNotes]); 
%the one we want to solve the E(hitting time)
ktosolve = 1;
%This is a changed version of the matrix from the approach
absorbprobmatrix = absorbprobmatrix;
absorbprobmatrix(ktosolve,:) =zeros(1,numNotes);
absorbprobmatrix(ktosolve,ktosolve) = 1;
syms eqnarray
for(j = 1:numNotes)
    eqnarray(j) = K(j)- sum(absorbprobmatrix(j,:).*K)  ==1;   
end
eqnarray(ktosolve) = 0;
[A,B] = equationsToMatrix(eqnarray,[K(1:ktosolve-1),K(ktosolve+1:end)]);

%since 'k21' == 0 we just subtract it so we can convert to double
expHittingTime = linsolve(A,B) - ('k'+string(ktosolve));
expHittingTime=double(expHittingTime);