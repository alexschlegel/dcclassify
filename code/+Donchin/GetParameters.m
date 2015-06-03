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
	%maximum sample time point is
	%t.window.start+t.gcsignal.start.max+param.t.lag.max+param.t.window.duration
	%which should be <= t.window.end
	
	%task classification
		param.task.t.window.start	= -1.5;	%start time of the trial windows, relative to imperative
		param.task.t.window.end		= 1.5;	%end time of the trial windows
		param.task.t.window.pad		= 8;	%padded window duration, for filtering (see http://www.fieldtriptoolbox.org/faq/what_kind_of_filters_can_i_apply_to_my_data)
		
		param.task.t.gcsignal.start.min		= 0;	%minimum start time of the source signal used for GC calculation, relative to window start
		param.task.t.gcsignal.start.max		= 1.5;	%maximum start time
		param.task.t.gcsignal.start.step	= 0.1;	%start time step
		param.task.t.gcsignal.duration		= 1;	%duration of the GC signals
		
		param.task.t.lag.min	= 0.025;	%minimum lag time for destination signal
		param.task.t.lag.max	= 0.5;		%maximum lag time
		param.task.t.lag.step	= 0.025;	%lag time step
	
	%task2 classification
		param.task2.t.window.start	= -3;	%start time of the trial windows, relative to imperative
		param.task2.t.window.end	= 1.25;	%end time of the trial windows
		param.task2.t.window.pad	= 8;	%padded window duration, for filtering (see http://www.fieldtriptoolbox.org/faq/what_kind_of_filters_can_i_apply_to_my_data)
		
		param.task2.t.gcsignal.start.min	= 0;	%minimum start time of the source signal used for GC calculation, relative to window start
		param.task2.t.gcsignal.start.max	= 3.5;	%maximum start time
		param.task2.t.gcsignal.start.step	= 0.05;	%start time step
		param.task2.t.gcsignal.duration		= 0.25;	%duration of the GC signals
		
		param.task2.t.lag.min	= 0.01;	%minimum lag time for destination signal
		param.task2.t.lag.max	= 0.5;	%maximum lag time
		param.task2.t.lag.step	= 0.01;	%lag time step
	
	%compute classification
		param.compute.t.window.start	= 0;	%start time of the trial windows, relative to imperative
		param.compute.t.window.end		= 2;	%end time of the trial windows
		param.compute.t.window.pad		= 6;	%padded window duration, for filtering (see http://www.fieldtriptoolbox.org/faq/what_kind_of_filters_can_i_apply_to_my_data)
		
		param.compute.t.gcsignal.start.min	= 0;	%minimum start time of the source signal used for GC calculation, relative to window start
		param.compute.t.gcsignal.start.max	= 1;	%maximum start time
		param.compute.t.gcsignal.start.step	= 0.1;	%start time step
		param.compute.t.gcsignal.duration	= 0.5;	%duration of the GC signals
		
		param.compute.t.lag.min		= 0.1;	%minimum lag time for destination signal
		param.compute.t.lag.max		= 0.5;	%maximum lag time
		param.compute.t.lag.step	= 0.1;	%lag time step
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
