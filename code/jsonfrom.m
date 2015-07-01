function s = jsonfrom(str)
% jsonfrom
% 
% Description:	wrapper for json.from because twitty is stupid
% 
% Syntax:	s = jsonfrom(str)
% 
% Updated: 2015-06-25
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
s	= json.from(str);
