# smnr-mgmnt

This is a Matlab class to manage and organize a one-day visit for academic seminars. 

It works together with a Google Form that collects department members' preferences about meetings and meals with the speaker. Given the preferences, it assigns people to meetings and meals, and creates a pdf document with the schedule for the day. 

## Dependencies

A copy of the following required libraries is included in the repo:

1. GetGoogleSpreadsheet library, which gets data from a Google Sheet: http://uk.mathworks.com/matlabcentral/fileexchange/39915-getgooglespreadsheet

2. Functions for the rectangular assignment problem, by Markus Buehren, which solves an optimal assignment problem: https://uk.mathworks.com/matlabcentral/fileexchange/6543-functions-for-the-rectangular-assignment-problem

The code uses LaTeX to create the schedule pdf file, hence the following is also needed:

3. ```pdflatex``` installed and on the ```$PATH```

The first two libraries are included and should be added to the Matlab path when using the class. 

## Usage

The file ```example_einstein.m``` contains a commented working example. The pdf file created with this example is also provided (```AlbertEinstein.pdf```).

## Logic of the code

Preferences are collected with a Google Form, that creates a Google Spreadsheet (<b>please do not edit the spreadsheet or the form! Make a copy and edit the copy</b> ).

The form template can be found here: 

https://docs.google.com/forms/d/1DA4pxHU2JE8ujU98nIoX0Z8WeaCqxGexNXhU5ZQdZAU/edit?usp=sharing

The spreadsheet template can be found here: 

https://docs.google.com/spreadsheets/d/1CmJqWmzsgQBocXvR1PDBNL4mzw6oHHCpVl9hWifQlG4/edit?usp=sharing

Both have been created with information about the example file.

The code downloads the preferences' information from the Google Spreadsheet, and assigns the slots and the meals to the "right" people. 

Preferences are expressed as a number between 0 (cannot make it) and 5 (I really want that spot). 

### Preferences' manipulation

The assignment algorithm performs a cost minimization. Therefore, one crucial assumption is how we go from preferences to cost. 

Preferences are numbers between 0 and 5. 
I define unweighted cost for all strictly positive numbers as 

        6 - the value of the preference for a slot/meal. 

The zeros in the preference matrix imply that the person cannot make that slot. Hence, they are set to ```Inf```, so that the cost minimization will never choose that assignment. 

Then, ```weighted_preferences``` is defined as 

        (1/interest)*cost

These are the weighted cost values used in the minimization problem that calculates the optimal assignment. 
### Priority

It is often crucial that the speaker meets with people from the same field or with a high interest in her/his research. Hence, the code gives priority to those who expressed high interest in the speaker. One of the information collected with the Google Form is the interest in the speaker (scale from 1 to 5, where 5 is the highest). Preferences are then weighted by the interest value. 

### Meals

The code sorts people that want to attend meals. It first assigns people to dinner. Then eliminates people that go for dinner from the list of people available for lunch, and assign the lunch slots. 

### Meeting slots

These are assigned with an assignment algorithm, so that the total cost of the assignment is minimized. Cost is defined as 1/weighted_preferences, where the weighted_preferences are obtained by multiplying the preference by the interest (see code for details)

## Collaborating

This is pretty much work in progress, and a very rough first attempt at it. 
Please feel free to open issues, propose enhancements, give comments, and create pull requests. 

Contact: meleantonio@gmail.com
