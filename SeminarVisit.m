classdef SeminarVisit < handle
    % SeminarVisit is a class for organizing a one-day seminar visit.
    
    properties (Access = public)
        % these are all strings
        firstnamespeaker % first name of the speaker
        lastnamespeaker % last name of the speaker
        namespeaker % full name of the spekaer
        datevisit % date of the visit
        emailspeaker % email address of the speaker
        webspeaker % webpage of the speaker
        researchbio % research interests of the speaker
        papertitle % paper to be presented
        paperurl % url of the pdf of the paper
        googleformid % Google Spreadsheet ID where preferences for slots and meals are stored; NOTICE: Google Spreadsheet should be accessible to anyone with the link
        office % office where the speaker will be hosted
        restaurantLunch % restaurant for lunch
        restaurantDinner % restaurant for dinner
        % these are cells or cell arrays
        slots = {}% available slots
        names = {}% people who expressed interest in the speaker
        mealspreferences = {} % preferences for lunch and dinner
        slots_who = {} % final allocation for slots
        dinner_who = {} % final allocation for dinner
        lunch_who = {} % final allocation for dinner
        % these are matrices
        slotpreferences = [] % preferences for slots
    end
    
    methods
        function obj = SeminarVisit(firstnamespeaker, ...
            lastnamespeaker, ...
            datevisit, ...
            emailspeaker , ...
            webspeaker, ...
            researchbio, ...
            papertitle, ...
            paperurl, ...
            googleformid, ...
            office, ...
            restaurantLunch, ...
            restaurantDinner)
            % SeminarVisit: Construct an instance of this class

            obj.firstnamespeaker = firstnamespeaker;
            obj.lastnamespeaker = lastnamespeaker;
            obj.namespeaker = [obj.firstnamespeaker, obj.lastnamespeaker];
            obj.datevisit = datevisit; 
            obj.emailspeaker = emailspeaker; 
            obj.webspeaker = webspeaker;
            obj.researchbio = researchbio;
            obj.papertitle = papertitle;
            obj.paperurl = paperurl;
            obj.googleformid = googleformid;
            obj.office = office;
            obj.restaurantLunch = restaurantLunch;
            obj.restaurantDinner = restaurantDinner;
        end
        
        function [G, slots, names,weighted_preferences, mealspreferences ] = extract_preferences(obj)
            % EXTRACT_PREFERENCES: downloads preferences collected with the Google Form, stores them into private properties
            % Notice: the Google Form and the Google Spreadsheet must be organized according to a specific format (see example at xxxxxxxxx)
            % IMPORTANT: you need to make the google spreadsheet associated with the form either public or visible for whoever has the link. If it is private, the code will not extract the preferences. 
            % Uses the GetGoogleSpreadsheet library, by Daniel, available at:  http://uk.mathworks.com/matlabcentral/fileexchange/39915-getgooglespreadsheet

            G = GetGoogleSpreadsheet(obj.googleformid) ; % download the data into a matrix
            [gr,gc ] = size(G);

            %% rename some variables
            % interest
            interest = G(2:end,3);

            % slots' times
            for k=4:gc-2
                tempslot = strsplit(char(G(1,k)),'[');
                slots{k-3} = tempslot{2}(1:end-1);
            end

            % colleagues' names
            names = G(2:end,2);

            % extract the preferences matrix
            preftemp = G(2:end,4:end-2);
            [rp,cp] = size(preftemp);
            S = sprintf('%s ', preftemp{:});
            inv_preferences = reshape(sscanf(S, '%f'), rp,cp);

            % reverse order, so that they are costs instead of utilities
            preferences = 6 - inv_preferences;
            preferences(preferences==6)= Inf; %

            [rpref, cpref] = size(preferences);

            % transform interest vector into numerical
            [ri,ci] = size(interest);
            Si = sprintf('%s ', interest{:});
            interest = reshape(sscanf(Si, '%f'), ri,ci);

            % weight preferences by interest
            weighted_preferences = (1./(repmat(interest, 1,cpref))).*preferences;

            % extract dinner preferences
            dinnerpref = interest.*str2num(char(G(2:end,end)));

            % extract lunch preferences
            lunchpref = interest.*str2num(char(G(2:end,end-1)));

            % combine the two
            mealspreferences ={dinnerpref, lunchpref};

            % assign preferences to object properties
            obj.slots = slots;
            obj.names = names;
            obj.slotpreferences = weighted_preferences;
            obj.mealspreferences = mealspreferences;
        end

        function [slots_who, assignment, cost] = assigntoslots(obj)
            % ASSIGNTOSLOTS: assigns people to slots, by choosing an optimal assignment given weighted preferences
            % Input: object instance
            % Outputs:
            % slots_who:  cell with names and corresponding slots for meetings
            % assignment: vector containing the assigned slot for each name
            % cost: total cost of the assignment

            % calculate the optimal assignment for meetings
            % NOTE: the assignment elements equal to zero are people who won't
            % meet the visitor
            [assignment, cost] = assignmentoptimal(obj.slotpreferences);
            
            % assigning names to slots
            names_temp = obj.names; 
            names_temp2 = names_temp(find(assignment~=0)); % eliminate people that are not assigned to any slot
            assignment2 = assignment(assignment~=0);
            
            for i = 1: length(assignment2)
                slots_who1(i) = names_temp2(assignment2==i) ; % get the right name
                slots_who2(i) = obj.slots(i); % get the right slots associated with the name
            end
            
            % collect names and slots in a cell
            slots_who = {slots_who1 slots_who2};

            % overwrite slots_who into object properties
            obj.slots_who = slots_who';

        end

        function [dinner_who, lunch_who] = assigntomeals(obj, dinner_slots, lunch_slots)
            % ASSIGNTOMEALS: assigns people to dinner and lunch. First assigns people to dinner, then to lunch (excluding people that have been selected for dinner). This is done by sorting preferences and then choosing the top dinner_slots people, then excluding them from the lunch list of candidates and choosing the top lunch_slots people from the latter.
            % 
            % INPUTS:
            % obj : instance of the object
            % dinner_slots : how many slots there are for dinner
            % lunch_slots :  how many lunch slots there are
            %
            % OUTPUTS:
            % dinner_who: names of people going for dinner
            % lunch_who: names of people going for lunch
            
            [sortedValuesDinner,sortedIndexDinner] = sort(obj.mealspreferences{1},'descend');  % Sort the values in descending order
            sortedIndexDinner = sortedIndexDinner(sortedValuesDinner~=0); % eliminate the zeros
            dinner_available = length(sortedIndexDinner); % establish how many people are available for dinner

            if dinner_available>=dinner_slots
                maxIndexDinner = sortedIndexDinner(1:dinner_slots);  % get the first dinner_slots people
            else
                maxIndexDinner = sortedIndexDinner(1:dinner_available); 
            end

            for j = 1:length(maxIndexDinner)
                dinner_who{j} = obj.names{maxIndexDinner(j)};
            end

            % exclude colleagues that go for dinner from lunch ranking
            obj.mealspreferences{2}(maxIndexDinner) = -1;

            % assign people to lunch
            [sortedValuesLunch,sortedIndexLunch] = sort(obj.mealspreferences{2},'descend');  % Sort the values in descending order
            sortedIndexLunch = sortedIndexLunch(sortedValuesLunch>=0); % eliminate the zeros and the -1s
            lunch_available = length(sortedIndexLunch); % establish how many people are available for lunch

            if lunch_available>=lunch_slots
                maxIndexLunch = sortedIndexLunch(1:lunch_slots);  % get the first lunch_slots people
            else
                maxIndexLunch = sortedIndexLunch(1:lunch_available); 
            end


            for j = 1:length(maxIndexLunch)
                lunch_who{j} = obj.names{maxIndexLunch(j)};
            end

            % update object properties
            obj.dinner_who = dinner_who; 
            obj.lunch_who = lunch_who;
            
        end
        
        function schedule_pdf(obj, rootfolder, seminartime, seminarroom, lunchtime, dinnertime)
            % SCHEDULE_PDF produces a pdf version of the schedule, written in LaTeX and compiled with pdflatex
            % INPUTS:
            % obj : instance of the class
            % these are all strings: 
            % rootfolder : folder where we add a subfolder containing the documents
            % seminartime : time at which the seminar is scheduled, must be in the format hh.mm (24 hours)
            % seminarroom : room where the seminar will be 
            % lunchtime : time at which the lunch is scheduled, must be in the format hh.mm (24 hours)            
            % dinnertime : time at which the dinner is scheduled, must be in the format hh.mm (24 hours)

            cd(rootfolder);
            if ~isfolder(obj.namespeaker)
                mkdir(obj.namespeaker); % create new folder
            end

            cd(obj.namespeaker); % move to the new folder 

            fid = fopen([obj.namespeaker,'.tex'], 'w'); % create a new tex file with the name of the speaker

            fprintf(fid, '%% Document settings \n');
            fprintf(fid, '\\documentclass[11pt]{article} \n');
            fprintf(fid, '\\usepackage[margin=1in]{geometry} \n');
            fprintf(fid, '\\usepackage[pdftex]{graphicx} \n');
            fprintf(fid, '\\usepackage{multirow} \n');
            fprintf(fid, '\\usepackage{setspace} \n');
            fprintf(fid, '\\usepackage{hyperref} \n');
            % fprintf(fid, '\\usepackage{natbib} \n');
            fprintf(fid, '\\pagestyle{plain} \n');
            fprintf(fid, '\\setlength\\parindent{0pt} \n');


            fprintf(fid, '\\begin{document} \n');


            fprintf(fid, '\\begin{tabular}{ l l } \n');
            fprintf(fid, '  \\multirow{3}{*}{ } & \\LARGE  \\\\ \\\\ \n');
            % fprintf(fid, '  \\multirow{3}{*}{\\includegraphics{..//logosurrey.jpg}} & \\LARGE  \\\\ \\\\ \n');
            fprintf(fid, ['  & \\LARGE \\textbf{',obj.firstnamespeaker,' ', obj.lastnamespeaker,' visit} \\\\ \\\\  \n']);
            fprintf(fid,[ '  & ', obj.datevisit,'  \n']);
            fprintf(fid, '\\end{tabular} \n');
            fprintf(fid, '\\vspace{10mm} \n \n');

            fprintf(fid, '%% Info about speaker \n');
            fprintf(fid, '\\begin{tabular}{ l l } \n');

            % this is for speaker's picture, needs to be in the "newfolder" in jpg
            % format and the name must be "namespeaker"
            % fprintf(fid, [' \\multirow{6}{*}{\\includegraphics[height=3.2cm]{',namespeaker,'.jpg}} & \\large \\textbf{',firstnamespeaker,' ', lastnamespeaker,'}  \\\\\\\\ \n']);
            fprintf(fid, [' \\multirow{6}{*}{} & \\large \\textbf{',obj.firstnamespeaker,' ', obj.lastnamespeaker,'}  \\\\\\\\ \n']);

            fprintf(fid, ['  & \\large \\href{mailto:',char(obj.emailspeaker),'}{',obj.firstnamespeaker,'''s email} \n']);
            fprintf(fid, '  \\\\ \\\\  \n');
            fprintf(fid, ['  & \\large \\href{',char(obj.webspeaker),'}{',obj.firstnamespeaker,'''s webpage}  \n']);
            fprintf(fid, '  \\\\ \\\\ \n');
            fprintf(fid, ['  & \\large Office: ', obj.office, ' \\\\ \n']);
            fprintf(fid, '\\end{tabular} \n');
            fprintf(fid, '\\vspace{10mm} \n \n');



            fprintf(fid, '%%%%%%%%%%%%  \n');
            fprintf(fid, '%% Research bio \n');
            fprintf(fid, '%%%%%%%%%%%% \n');

            fprintf(fid, ['\\textbf {\\large \\\\ Research bio:} ', obj.firstnamespeaker,'''s research is on ', obj.researchbio, ' \n']);

            fprintf(fid, '\\vspace{5mm} \n');

            fprintf(fid, '%% Day Outline \n');

            fprintf(fid, '\\begin{center} \n');
            fprintf(fid, '\\Large{\\textbf{Agenda}} \n');
            fprintf(fid, '\\end{center} \n');

            fprintf(fid, ['\\textbf{Wednesday ', obj.datevisit, '}  \n']);

            fprintf(fid, '\\begin{table}[h!]  \n');
            fprintf(fid, '\\normalsize \n');
            fprintf(fid, '\\begin{tabular}{ r  l  l} \n');
            fprintf(fid, '\\hline \n');
            fprintf(fid, '\\textbf{Time} & \\textbf{What}  & \\textbf{Where} \\\\ \n');
            fprintf(fid, '\\hline \\hline\n');
            fprintf(fid, '\\\\\\ \n');

            % Create the meetings, lunch, dinner, and seminar
            % fill up the schedule with meetings, lunch, seminar, dinner

            % create strings for lunch and dinner attendees
            [dinner_attendees, lunch_attendees] = obj.convert_to_usable_string;

            % schedule is created here
            try
                flag_lunch = 0; % flag for  lunch 
                flag_seminar = 0; % flag for seminar
                flag_dinner = 0; % flag for dinner 
                for event = 1: length(obj.slots) 

                    % if it's time for seminar, then schedule seminar
                    if str2num(char(obj.slots_who{2}(event))) > str2num(seminartime) && flag_seminar == 0 
                        fprintf(fid, [char(seminartime) ' & \\begin{minipage}{.65\\textwidth}Seminar:  \\href{',obj.paperurl,'}{``',obj.papertitle,'"  }\\end{minipage}  & ' seminarroom ' \\\\ \n']);
                        fprintf(fid, '\\vspace{1mm} \n');
                        flag_seminar = 1;
                    end  

                    % if it's time for lunch, then schedule lunch
                    if str2num(char(obj.slots_who{2}(event))) > str2num(lunchtime) && flag_lunch == 0 
                        fprintf(fid, [char(lunchtime) ' & Lunch with ', lunch_attendees, '  & ' obj.restaurantLunch ' \\\\ \n']);
                        fprintf(fid, '\\vspace{1mm} \n');
                        flag_lunch = 1;
                    end
                    
                    % if it's time for dinner, then schedule dinner
                    if (str2num(char(obj.slots_who{2}(event))) > str2num(dinnertime) && flag_dinner == 0) 
                        fprintf(fid, [char(dinnertime) ' & Dinner with ', dinner_attendees, '  & ' obj.restaurantDinner ' \\\\ \n']);
                        fprintf(fid, '\\vspace{1mm} \n');
                        flag_dinner = 1;
                    end

                    if event <= length(obj.slots)
                        fprintf(fid, [char(obj.slots_who{2}(event)), ' & Meet with ', char(obj.slots_who{1}(event)), ' & ', obj.office,'  \\\\ \n']);
                        fprintf(fid, '\\vspace{1mm} \n');
                        if event == length(obj.slots) && flag_dinner == 0
                            fprintf(fid, [char(dinnertime) ' & Dinner with ', dinner_attendees, '  & ' obj.restaurantDinner ' \\\\ \n']);
                            fprintf(fid, '\\vspace{1mm} \n');
                            flag_dinner = 1;
                        end
                    end
                end
            catch ME
                error('Something went wrong', ME)
            end

            fprintf(fid, '\\end{tabular} \n');
            fprintf(fid, '\\end{table} \n');
            fprintf(fid, '\\end{document} \n');


            fclose (fid); % close the file

            % print pdf schedule
            system(['pdflatex -synctex=1 -interaction=nonstopmode ',obj.namespeaker,'.tex']);
            
        end

        function [usable_string_dinner, usable_string_lunch] = convert_to_usable_string(obj)
            % CONVERT_TO_USABLE_STRING : utility to create strings to be used for lunch and dinner attendees

            usable_string_dinner = obj.dinner_who{1};
            usable_string_lunch = obj.lunch_who{1}; 

            for a = 2: length(obj.dinner_who)
                if a <=length(obj.dinner_who)-1
                    usable_string_dinner = [usable_string_dinner, ', ' obj.dinner_who{a} ];
                else
                    usable_string_dinner = [usable_string_dinner, ' and ' obj.dinner_who{a} ];
                end
            end
            for b = 2: length(obj.lunch_who)
                if b <=length(obj.lunch_who)-1
                    usable_string_lunch = [usable_string_lunch, ', ' obj.lunch_who{b} ];
                else
                    usable_string_lunch = [usable_string_lunch, ' and ' obj.lunch_who{b} ];
                end
            end

        end

    end
end

