function ui_report_fmri(D,s,i)
% Interactive review of fMRI design matrix
% FORMAT ui_report_fmri(D,s,i)
%
% Copied with minor edits from:
% @(#)spm_fMRI_design_show.m	2.22 Karl Friston 03/02/21
%
% $Id$

SPM = des_struct(D);
Sess  = SPM.Sess;

% Do not proceed unless there are trials specified
%-----------------------------------------------------------------------
for j = 1:length(Sess)
    if ~length(Sess(j).U)
        spm('alert*','User-specifed regressors only!',mfilename,sqrt(-1));
        return
    end
end

%-Defaults: Setup GUI if not called by spm_DesRep (with s and i)
%-----------------------------------------------------------------------
if nargin < 3
	s = 1;
	i = 1;

	%-Get Interactive window and delete any previous DesRepUI menu
	%---------------------------------------------------------------
	Finter = spm_figure('GetWin','Interactive');
	delete(findobj(get(Finter,'Children'),'flat','Tag','DesRepUI'))

	%-Create menu
	%---------------------------------------------------------------
	hC     = uimenu(Finter,'Label','Explore fMRI design',...
		'Separator','on',...
		'Tag','DesRepUI',...
		'UserData',D,...
		'HandleVisibility','on');
	for j = 1:length(Sess)
		h     = uimenu(hC,'Label',sprintf('Session %.0f ',j),...
			'HandleVisibility','off');
		for k = 1:length(Sess(j).Fc)
			cb = ['tmp = get(get(gcbo,''UserData''),',...
					         '''UserData''); ',...
				sprintf(['ui_report_fmri(',...
					'tmp,%d,%d);'],j,k)];
			uimenu(h,'Label',Sess(j).Fc(k).name,...
	     	   	         'CallBack',cb,...
	     	   	         'UserData',hC,...
	     	   	         'HandleVisibility','off')
		end
	end
end


%-Graphics...
%=======================================================================

%-Get Graphics window
%-----------------------------------------------------------------------
Fgraph = spm_figure('GetWin','Graphics');
spm_results_ui('Clear',Fgraph,0)


% Trial-specific regressors - time domain
%-----------------------------------------------------------------------
sX    = SPM.xX.X(Sess(s).row,Sess(s).col);
rX    = sX(:,Sess(s).Fc(i).i);
subplot(2,2,1)
plot(Sess(s).row,rX)
xlabel('scan')
ylabel('regressor[s]')
title({'Time domain',['regressors for ' Sess(s).Fc(i).name]})
grid on
axis tight

% Trial-specific regressors - frequency domain
%-----------------------------------------------------------------------
subplot(2,2,2)
gX    = abs(fft(rX)).^2;
gX    = gX*diag(1./sum(gX));
q     = size(gX,1);
Hz    = [0:(q - 1)]/(q*SPM.xY.RT);
q     = 2:fix(q/2);
plot(Hz(q),gX(q,:))
patch([0 1 1 0]/128,[0 0 1 1]*max(max(gX)),[1 1 1]*.9)
xlabel('Frequency (Hz)')
ylabel('relative spectral density')
title({'Frequency domain','128 second High-pass filter'})
grid on
axis tight


% if trial (as opposed to trial x trial interaction)
%-----------------------------------------------------------------------
if length(Sess(s).U) >= i

	% Basis set and peristimulus sampling
	%---------------------------------------------------------------
	subplot(2,2,3)
	dt   = Sess(s).U(i).dt;
	RT   = SPM.xY.RT;
	t    = [1:size(SPM.xBF.bf,1)]*dt;
	pst  = Sess(s).U(i).pst;
	plot(t,SPM.xBF.bf,pst,0*pst,'.','MarkerSize',16)
	str  = sprintf('TR = %0.2fsecs',RT);
	xlabel({'time (secs)' str sprintf('%0.0fms time bins',1000*dt)})
	title({'Basis set and peristimulus sampling' SPM.xBF.name})
	axis tight
	grid on

	% if a paramteric variate is specified
	%---------------------------------------------------------------
	for p = 1:length(Sess(s).U(i).P)

	    if Sess(s).U(i).P(p).h

		% onsets and parametric modulation
		%-------------------------------------------------------
		subplot(2,2,4)
		ons = Sess(s).U(i).ons;
		plot(ons,Sess(s).U(i).P(p).P,'.','MarkerSize',8)
		xlabel('time {secs}')
		title('parameters')
		grid on
		hold on

	    end
	end
end

%-Pop up Graphics figure window
%-----------------------------------------------------------------------
figure(Fgraph);
