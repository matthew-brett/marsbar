function D = autocorr(D, autocorr_type, varargin)
% method to set autocorrelation types for design
% FORMAT D = autocorr(D, autocorr_type, varargin)
% 
% D             - design object
% autocorr_type - autocorrelation type specification, one of
%                 'SPM'
%                 'fmristat'
%                 'none'
% varargin      - parameters defining autocorrelation model.  One of 
%                 (SPM) vector with estimated AR coefficients [0.2]
%                 (fmristat) order of fmristat model [1]
% 
% $Id$
  
if nargin < 2
  error('Need autocorr type');
end

if ~is_fmri(D)
  warning('Can only set autocorrelation for FMRI design types');
  return
end

% Get design, put into some useful variables
v_f = verbose(D);
SPM = des_struct(D);
nscan = size(SPM.xX.X, 1);

switch lower(autocorr_type)
 case 'fmristat'
  % Fit fmristat model AR(n)
  if nargin < 3, varargin{1} = 1; end
  cVi = varargin{1};
  if prod(size(cVi)) > 1
    error('Expecting scalar for fmristat order');
  end
  SPM.xVi.Vi = struct('type', 'fmristat', 'order', cVi);
  cVi        = sprintf('fmristat AR(%d)',cVi);
  f2cl       = 'V'; % Field to CLear
  SPM.xVi.cov_calc = 'summary';
  
 case 'spm'
  % SPM AR coefficient(s) to be specified
  if nargin < 3, varargin{1} = 0.2; end
  cVi = varargin{1};
  if any(cVi > 1 | cVi < 0)
    error('Rho estimates should be > 0 and < 1');
  end
  SPM.xVi.Vi = pr_spm_ce(nscan, cVi);
  cVi        = sprintf('AR(%0.1f)',cVi(1));
  f2cl       = 'V'; 
  
 case 'none'		
  %  xVi.V is i.i.d
  %---------------------------------------------------------------
  SPM.xVi.V  = speye(sum(nscan));
  cVi        = 'i.i.d';
  f2cl       = 'Vi'; 
  
 otherwise		
  error(['Eccentric autocorr type ' autocorr_type]);
end

% If we've set V, need to clear Vi, because the
% estimate method takes the presence of Vi to mean that
% V can be cleared, with 'redo_covar' flag
% Conversely V needs to be cleared if Vi was estimated
if isfield(SPM.xVi, f2cl)
  SPM.xVi = rmfield(SPM.xVi, f2cl);
  if v_f, fprintf('Clearing previous %s matrix\n', f2cl); end
end

% Also: remove previous W matrices
% Either will need to be recalculated or won't be used
if isfield(SPM.xX, 'W')
  SPM.xX = rmfield(SPM.xX, 'W');
  if v_f, fprintf('Clearing previous W matrix\n'); end
end

% fill into design
SPM.xVi.form = cVi;
xsDes = struct('Intrinsic_correlations', SPM.xVi.form);
SPM.xsDes = mars_struct('ffillmerge', SPM.xsDes, xsDes);

% put stuff into object
D = des_struct(D,SPM);