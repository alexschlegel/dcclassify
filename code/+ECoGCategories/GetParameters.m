function param = GetParameters()
% ECoGCategories.GetParameters
% 
% Description:	get parameters for the ECoG Categories data and analyses
% 
% Syntax:	param = ECoGCategories.GetParameters()
% 
% Updated: 2015-06-05
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData

%time parameters, in sec
	%maximum sample time point is
	%t.gcsignal.start.max+param.t.lag.max+param.t.window.duration
	%which should be <= t.window.end
	
	%category RSA
		param.t.gcsignal.start.min	= -1;	%minimum start time of the source signal used for GC calculation, relative to stimulus
		param.t.gcsignal.start.max	= 3;	%maximum start time
		param.t.gcsignal.start.step	= 0.1;	%start time step
		param.t.gcsignal.duration	= 0.5;	%duration of the GC signals
		
		param.t.lag.min		= 0.025;	%minimum lag time for destination signal
		param.t.lag.max		= 0.5;		%maximum lag time
		param.t.lag.step	= 0.025;	%lag time step
		
		param.t.window.start	= param.t.gcsignal.start.min;
		param.t.window.end		= param.t.gcsignal.start.max + param.t.lag.max + param.t.gcsignal.duration;
%trial rejection threshold, in uV
	%this should be 300 to detect interictal spikes, but that eliminates way too
	%many trials
		param.threshold.reject	= 1000;
%electrodes of interest
	param.channel.posterior	=	{
									'LTG01-REF'
									'LTG02-REF'
									'LTG03-REF'
									'LTG09-REF'
									'LTG10-REF'
									'LTG11-REF'
									'LTG17-REF'
									'LTG18-REF'
									'LTG19-REF'
									'LTG25-REF'
									'LTG26-REF'
									'LTG27-REF'
								};
	param.channel.anterior	=	{
									'LTG06-REF'
									'LTG07-REF'
									'LTG08-REF-1'
									'LTG14-REF'
									'LTG15-REF'
									'LTG16-REF-1'
									'LTG22-REF'
									'LTG23-REF'
									'LTG24-REF-1'
									'LTG30-REF'
									'LTG31-REF'
									'LTG32-REF-1'
								};
	
	param.channel.use	= [param.channel.posterior; param.channel.anterior];