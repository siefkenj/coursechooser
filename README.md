CourseMapper
=============

CourseMapper is software to help visualize a program of study.  
It was initially conceived of as a tool to help departments 
in curriculum planning efforts, but since then it has seen 
other uses, including communicating to students how a particular 
program's or specialized program's (for instance an Honors degree 
in Mathematics, or a Geography degree with a Coastal Studies 
emphasis) requirements flow from one year to the next.

A picture is worth a thousand words:
![Example Map](https://raw.githubusercontent.com/siefkenj/coursechooser/master/examples/geog-earth-systems-map.png)


One of CourseMapper's key features is that it connects to a
university's database of courses and prerequisites.  This way,
when drafting a program, one doesn't need full knowledge of all
the prerequisites of every course in a department!

For a live (an institutionalized) version of CourseMapper, visit 
http://www.uvic.ca/learningandteaching/leaders/home/planning-tool/index.php
In addition, there is end-user documentation at http://www.uvic.ca/learningandteaching/leaders/home/planning-tool/documentation.php


Want to use CourseMapper?
-------------------------

If you want to use CourseMapper at your institution, you will
need to do two things:

  1. Build an interface from your university's database to the 
 `JSON` course format used by CourseMapper.
  2. Brand CourseMapper appropriately.

  
Developer Information
=====================

CourseMapper has been developed primarily in Coffeescript.  Coffeescript
is a language for the web that compiles to Javascript is a straightforward
way, so if you're a developer familiar with Javascript, a transition should
not be hard.

The course information is stored on the server in JSON format, which
should be pretty straightforward.  A sample can be found at
http://web.uvic.ca/~siefkenj/coursechooser/course_data/MATH.json

If you want to get a
local copy going, create a `course_data` folder and copy some of the JSON
files from the UVic webpage into the `course_data` directory, and things should
start working.

For the `JSON`, the prerequisites format is as follows:

  PREREQ = {"data": [PREREQ | COURSE], "op":  OP}
  OP = "or" | "and"
  COURSE = {"number": NUMBER, "subject": SUBJECT}
  NUMBER = the course number
  SUBJECT = the course subject (eg, MATH or ECON, etc)

As for how it all works, a directed graph is created where courses are
nodes and prereqs have arrows between them.  A program called _graphviz_
(which has been compiled to Javascript) is called to lay out the graph
and minimize the overlapping of edges.  CourseMapper then takes the
output from graphviz and creates the pretty graph in `SVG` format.  In the
`SVG` a `JSON` copy of the graph is also stored so it can be reloaded
sometime in the future.

The interface is built with jquery and jqueryUI.

The files in js/ do the following things:

 * `coursechooser.js`
  Main logic for the UI

 * `dotgraph.js`
  Javascript code for generating graphviz file formats

 * `dotparser.js`
  Javascript code for parsing graphviz output

 * `graphview.js`
  Code for an interactive student view

 * `jquery.json-2.3.js`
   `jquery.ui.combobox.js`
  JQueryUI

 * `jstorage.js`
  JQuery library for local storage

 * `numeric-1.2.6.js`
  Javascript matrix; used for optimizing graph output

 * `plugins.js`
  Compatibility for older browsers

 * `script.js`
  ...empty? Probably don't need this

 * `svggraph.js`
  Javascript to turn parsed graphviz output into SVG

 * `viz-2.26.3.js`
  graphviz version 2.26.3 compiled to javascript

 * `viz-worker.js`
  code to run viz.js as a webworker (so it runs in a separate thread and
  doesn't lock the UI)

There is a little bending over backwards to get coursemapper to run
as a web app.  In particular, to save a file with a proper filename,
CourseMapper
runs a `php` script to echo the contents of a file back to the
browser (otherwise you cannot control the file name in Firefox).  Since
the creation of `CourseMapper` there are some new and better established libraries
that do a better job. (Upgrading CourseMapper to use one of these libraries
would be a great first commit!)


If you make worthwile changes to CourseMapper, please send a pull request :-).
