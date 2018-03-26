%% Housekeeping
clear all; clc;

addpath(genpath('../../smnr-mgmt')); % adding repo to path


%% Create an instance of the object
% The following properties of the object must be provided when creating the instance of the object:
% firstnamespeaker % first name of the speaker
% lastnamespeaker % last name of the speaker
% namespeaker % full name of the spekaer
% datevisit % date of the visit
% emailspeaker % email address of the speaker
% webspeaker % webpage of the speaker
% researchbio % research interests of the speaker
% papertitle % paper to be presented
% paperurl % url of the pdf of the paper
% googleformid % Google Spreadsheet ID where preferences for slots and meals are stored; NOTICE: Google Spreadsheet should be accessible to anyone with the link
% office % office where the speaker will be hosted
% restaurantLunch % restaurant for lunch
% restaurantDinner % restaurant for dinner

alberteinstein = SeminarVisit('Albert', 'Einstein', '32/13/4520', 'a.einstein@relativity.general', 'www.alberteinstein.genius', 'nuclear physics.', 'Theory of General Relativity', 'www.alberteinstein.gemius/genrel.pdf', '1CmJqWmzsgQBocXvR1PDBNL4mzw6oHHCpVl9hWifQlG4', '1', 'Chez Supersimmetry', 'The Hungry Electron') ;

%% extract the preferences and store them in new variables
% G: preferences' data
% slots: cell of strings with the slots' times
% names: cell of strings with the names of the colleagues that expressed a preference in the Google Form
% weighted_preferences: preferences weighted for the expressed interest in the speaker (see the README file for how priority is associated with expressed interest)
% mealspreferences: cell containing two cells of strings with preferences about meals
[G, slots, names, weighted_preferences, mealspreferences ] = alberteinstein.extract_preferences;

%% assign meeting slots to people
% slots_who: cell that contains names and slots of the peerson assigned to each slot
% assignment: a vector containing the slot assigned to each person in the corresponding position on the names cell
% cost: this is the cost of the allocation
[slots_who, assignment, cost] = alberteinstein.assigntoslots; 

% assign meals
% need to provide two inputs: number of seats at dinner and number of seats at lunch (excluding the speaker)
[dinner_allocation, lunch_allocation] = alberteinstein.assigntomeals(3,2);

%% Provide parameters for the pdf file
% need to set
% rootolder: where you want the pdf file to be stored
% seminartime: a string with the seminar time
% seminarroom: a string with the seminar room
% lunchtime: string with lunch time
% dinnertime: a string with dinner time

rootfolder = '../../smnr-mgmt';
seminartime = '11.00';
seminarroom = 'Seminar Room 42';
lunchtime = '12.30';
dinnertime = '19.00';

%% Produce schedule pdf file (called AlbertEintein.pdf and contained in the folder AlbertEinstein)
alberteinstein.schedule_pdf(rootfolder, seminartime, seminarroom, lunchtime, dinnertime)