function param = GetParameters()
% Donchin.GetParameters
% 
% Description:	GetParameters subfunction copied from Analysis_20120109b
% 
% Syntax:	param = GetParameters()
% 
% Updated: 2015-05-13
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData

%filter parameters, in Hz
	param.filter.lp		= 150;	%low pass filter upper bound
	param.filter.hp		= 0.1;	%high pass filter lower bound
	param.filter.order	= 3;	%default filter order (4) gives an error
%time parameters, in sec
	param.t.window.start	= 0;	%start time of the trial windows, relative to imperative
	param.t.window.end		= 2;	%end time of the trial windows
	param.t.window.pad		= 6;	%padded window duration, for filtering (see http://www.fieldtriptoolbox.org/faq/what_kind_of_filters_can_i_apply_to_my_data)
	
	param.t.gcsignal.start.min	= 0;	%minimum start time of the source signal used for GC calculation, relative to window start
	param.t.gcsignal.start.max	= 1;	%maximum start time
	param.t.gcsignal.start.step	= 0.1;	%start time step
	param.t.gcsignal.duration	= 0.5;	%duration of the GC signals
	
	param.t.lag.min		= 0.1;	%minimum lag time for destination signal
	param.t.lag.max		= 0.5;	%maximum lag time
	param.t.lag.step	= 0.1;	%lag time step
	
	%minimum sample time point is t.window.start+t.gcsignal.start.min
	%maximum sample time point is t.window.start+t.gcsignal.start.max+param.t.lag.max+param.t.window.duration
	%	which should be <= t.window.end
	%	currently 0+1+0.5+0.5
%trial rejection threshold, in uV
	param.threshold.reject	= 80;
%electrodes of interest
	param.channel.posterior	= {'Oz';'Pz';'O1';'PO3';'P3';'P7';'O2';'PO4';'P4';'P8'};
	param.channel.anterior	= {'AF3';'F3';'F7';'Fc1';'FC5';'AF4';'F4';'F8';'FC2';'FC6'};
	param.channel.reject	= {'Fp1';'Fp2'};
	
	param.channel.heog.left		= 'EXG1';	%left outer canthus
	param.channel.heog.right	= 'EXG2';	%right outer canthus
	param.channel.veog.upper	= 'EXG3';	%right eye supra orbit
	param.channel.veog.lower	= 'EXG4';	%right eye sub orbit
	param.channel.mastoid.left	= 'EXG5';	%left mastoid
	param.channel.mastoid.right	= 'EXG6';	%right mastoid
	param.channel.fdi.left		= 'EXG7';	%this is just what EEGChannel says
	param.channel.fdi.right		= 'EXG8';	%this is just what EEGChannel says
	
	param.channel.ref	= {param.channel.mastoid.left; param.channel.mastoid.right};
	param.channel.use	= [param.channel.posterior; param.channel.anterior; param.channel.reject; param.channel.ref];
%trigger codes
	warning('off','all');
	
	strDirDonchin	= DirAppend(strDirData,'donchin');
	cPathSession	= FindFiles(strDirDonchin,'^\d{2}\w{3}\d{2}\w{2,3}\.mat$');
	sSession		= load(cPathSession{1});
	%trigger codes are screwed up in the BDF file
	param.trigger	= structfun2(@(x) bin2dec(fliplr(dec2bin(x,16))),sSession.triggercode);
	
	param.trigger.timelock.all	= [param.trigger.imp_letter; param.trigger.err_keyearly];
	param.trigger.timelock.good	= param.trigger.imp_letter;
