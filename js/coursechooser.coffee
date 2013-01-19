objToString = (obj) ->
    ret = '{ '
    for p,v of obj
        ret += " #{p}:#{v}, "
    return ret + "}"

attachedToDom = (elm) ->
    if not elm or not elm.parentNode?
        return false
    else if elm.parentNode is document
        return true
    return attachedToDom(elm.parentNode)

objValsToArray = (obj) ->
    return (v for k,v of obj)

# returns the things in obj1 missing from obj2 and the things in obj2 missing from obj1
symmetricDiffObjects = (obj1, obj2) ->
    ret1 = {}
    ret2 = {}
    for k of obj1
        if not obj2[k]
            ret1[k] = obj1[k]
    for k of obj2
        if not obj1[k]
            ret2[k] = obj2[k]
    return {missing: ret1, excess: ret2}
objKeysEqual = (obj1, obj2) ->
    for k of obj1
        if not obj2[k]?
            return false
    for k of obj2
        if not obj1[k]?
            return false
    return true
# do a shallow copy of obj
dupObject = (obj) ->
    ret = {}
    for k,v in obj
        ret[k] = v
    return ret
# escape <,>,& in a string
htmlEncode = (str) ->
    str = '' + str
    try
        str = str.replace('&','&amp;','g').replace('<','&lt;','g').replace('>','&gt;','g')
    catch e
        console.log 'error, expected string, got', str
    return str

titleCaps = (str) ->
    upper = (word) ->
        return word.charAt(0).toUpperCase() + word.slice(1)
    exceptionalWords = /^(a|an|and|as|at|but|by|en|for|if|in|of|on|or|the|to|v[.]?|via|vs[.]?|with|amp|gt|lt)$/

    str = str.toLowerCase()
    tokens = ('' + str).split(/\b/)
    ret = ''
    firstWord = true
    for word,i in tokens
        # all words should be capitalized by default
        shouldCapitalize = true
        # if they are exceptional words, don't capitalize
        if word.match(exceptionalWords)
            shouldCapitalize = false
        # but if we are the first word in the sentence, capitalize
        if firstWord
            shouldCapitalize = true
        # if we are surrounded by &;, we are an html escape sequence, we should never be captialized
        if tokens[i-1]?.slice(-1) == '&' and tokens[i+1]?.charAt(0) == ';'
            shouldCapitalize = false

        # As soon as we encounter a non-whitespace word, we have seen the first
        # word in the sentence, so we don't need to worry about capitalizing it any longer
        if firstWord and word.match(/\b/)
            firstWord = false

        # check to see if we are a roman numeral.  If we are, capitalize specially, or else check if we
        # should capitalize the first letter
        if word.match(/^(i|v|x|l|c|d|m)+$/i)
            word = word.toUpperCase()
        else if shouldCapitalize
            word = upper(word)
        ret += word
    return ret

$(document).ready ->
    window.courseManager = new CourseManager
    window.courses = window.courseManager.courses

    $('.course-status').buttonset().disableSelection()
    $('button').button()
    $('#department-list').combobox()
    $('#tabs').tabs()

    window.courseManager.showCoursesOfSubject('MATH')
    $('#show-courses').click ->
        subjects = []
        courses = []
        try
            val = $('#department-list').combobox('value').toUpperCase()
            for v in val.split(/,\s*/)
                # see if it is a course and not just a subject
                # by checking if it has a number in it
                if v.match(/\d/)
                    # identify the subject and the number in such a way
                    # that they can be written with or without a space e.g. "math 100" or "math100"
                    subject = v.match(/[a-zA-Z]+/)?[0]
                    number = v.match(/\d\w+/)?[0]
                    courses.push {subject:subject, number:number}
                else
                    subjects.push v
        catch e
            subjects.push $('#department-list option:selected()').val()
        for v in subjects
            window.courseManager.showCoursesOfSubject(v)
        for c in courses
            # we need a closure here.  we are first making sure the subject of each course is loaded
            # and then we use a callback to show the course
            ((c) ->
                window.courseManager.loadSubjectData(c.subject, -> window.courseManager.ensureDisplayedInYearChart(c))
            )(c)
    $('#hide-courses').click ->
        subjects = []
        try
            val = $('#department-list').combobox('value')
            for v in val.split(/,\s*/)
                subjects.push v.toUpperCase()
        catch e
            subjects.push $('#department-list option:selected()').val()
        for v in subjects
            window.courseManager.hideCoursesOfSubject(v)

    # make the years droppable
    $('.year').droppable
        hoverClass: 'highlight'
        drop: (event, ui) ->
            courses = this.getElementsByClassName('courses')[0]
            courses.appendChild(ui.draggable[0])
            window.courseManager.selectCourse(ui.draggable[0].course)
            window.courseManager.courseMoved(ui.draggable[0].course)

    # setup the electives area
    $('#create-new-electives').click ->
        elective = new ElectivesButtonEditor({title:'Electives'}, window.courseManager)
        electiveButton = new ElectivesButton(elective)
        $('#electives-list').append(elective.getButton())
        $('#electives-list').append("<hr />")
        $('.year1 .courses').append(electiveButton.getButton())
        window.courseManager.addCourse(electiveButton)
        window.courseManager.sortableCourses[electiveButton] = electiveButton
        window.courseManager.addCourse(elective)
        window.courseManager.makeCourseButtonDraggable(electiveButton)
        window.courseManager.makeElectivesButtonDroppable(electiveButton)

###
# Class to manage and keep the sync of all course on the webpage
# and their state.
###
class CourseManager
    constructor: ->
        @courses = {}
        @courseData = {}
        @sortableCourses = {}   # all the courses that are displayed in the year chart (and so are sortable)
        @sortableCoursesStateButtons = {}
        @loadedSubjects = {}
    # updates the state of all instances of a particular course
    updateCourseState: (course, state) ->
        for c in (@courses[course] || [])
            c.setState(state)
        # update the prereqs list asyncronously with a little delay so it isn't
        # so surprising to the user
        window.setTimeout((=> @showUnmetPrereqs()), 500)
    addCourse: (course) ->
        hash = '' + course
        if not @courses[hash]
            @courses[hash] = []
        @courses[hash].push course
        return course
    removeCourse: (course) ->
        hash = '' + course
        if not @courses[hash]
            return false
        index = @courses[hash].indexOf(course)
        if index >= 0
            @courses[hash].splice(index, 1)
    removeAllCourseInstances: (course) ->
        delete @courses[course]
    cleanupUnattachedButtons: (course, buttonType=CourseButton) ->
        clean = =>
            if @needsCleaning = false
                return
            @needsCleaning = false
            courses = []
            if not course
                for k,v of @courses
                    courses = courses.concat(v)
            else
                hash = BasicCourse.hashCourse(course)
                courses = @courses[hash] || []
            for c in courses
                if c instanceof buttonType and not attachedToDom(c.elm)
                    c.removeButton()
                    @removeCourse(c)
            return
        @needsCleaning = true
        # this operation takes a bit of time, so do it asyncronously
        window.setTimeout(clean, 1000)

    # makes all electivesButtons have the same state as button (including
    # making the list of elective courses the same)
    updateElectivesButton: (button) ->
        data = button.getValues()
        # we will sync the courses manually, we don't want to have a shallow copy of the courses object!
        delete data.courses

        for electiveButton in (@courses[button] || [])
            # make sure each ElectivesButton has a list of the courses that button does
            # and only those courses
            diff = symmetricDiffObjects(button.courses, electiveButton.courses)
            for hash,course of diff['missing']
                newCourse = @createCourseButton(course, {clickable: true})
                electiveButton.addCourse(newCourse)
            for hash,course of diff['excess']
                electiveButton.removeCourse(course)

            electiveButton.update(data)

    # out of sortableCourses, ensures only course has the selected state
    #TODO make sure this works for Electives aswell
    selectCourse: (course) ->
        if not course
            return
        # identify the selected course and set its state
        selectedCourse = null
        for hash,c of @sortableCourses
            if c.state.selected
                c.setState({selected: false})
            if c.subject is course?.subject and c.number is course?.number
                c.setState({selected: true})
                selectedCourse = c
        if not selectedCourse
            return

        # set up the course info area for the selected course
        stateButtons = @sortableCoursesStateButtons[selectedCourse]
        if not stateButtons
            stateButtons = @createCourseStateButton(selectedCourse)
        $('.course-info .course-name .course-number').html selectedCourse.hash
        $('.course-info .course-name .course-title').html titleCaps(('' + selectedCourse.data.title).toLowerCase())
        # if we don't detach first, jquery removes all bound events and ui widgets, etc.
        $('.course-info .course-state').children().detach()
        $('.course-info .course-state').html stateButtons.elm
        $('.course-info .prereq-area').html PrereqUtils.prereqsToDivs(stateButtons.prereqs, @)
        #TODO this shouldn't be done with a timeout.  it should be done in a robust way!!
        window.setTimeout((=> $('#dot').val @createDotGraph()), 0)
        @cleanupUnattachedButtons()


    # returns a CourseButton for the desired course.  If the course
    # hasn't been loaded yet, it will be loaded and the CourseButton's data will
    # be updated accordingly
    createCourseButton: (course, ops={}) ->
        # if we've already been loaded, our job is easy
        if @courseData[course]
            course = new CourseButton(@courseData[course], true)
        else
            # if the course hasn't been loaded, we return a functioning course
            # button whose data will be updated upon load
            course = new CourseButton(course)
            updateCourse = =>
                if not @courseData[course]
                    if course.elm
                        course.$elm.addClass('defunct')
                    return
                    #throw new Error("Course #{course} was loaded in dep. #{course.subject}, but wasn't available")
                course.update(@courseData[course])
                course.wasSynced = true
            @loadSubjectData(course.subject, updateCourse)
        if ops.clickable
            @makeCourseButtonClickable(course, ops)
        if ops.draggable
            @makeCourseButtonDraggable(course, ops)
        @addCourse(course)
        @initButtonState(course)
        return course
    # makes it so that when you click the button,
    # it cycles through the states and ensures all instances
    # are appropriately synced
    makeCourseButtonClickable: (button, ops={}) ->
        # if we're selectable we should be keyboard navigatable too
        if ops.selectable
            button.$elm.attr({tabindex: 1})
            button.$elm.focus ->
                # make sure extra focus events don't trigger extra clicks
                # (for example, the element is focused, and somebody selects
                # the webpage titlebar, causing a new focus event to fire)
                if not @course.state.selected
                    @course.$elm.trigger('click')
            button.$elm.keydown (event) ->
                self = event.currentTarget
                siblings = event.currentTarget.parentNode.childNodes
                myIndex = null
                for node,i in siblings
                    if node == self
                        myIndex = i
                sibs = {}
                if myIndex + 1 < siblings.length
                    sibs.right = siblings[myIndex + 1]
                if myIndex - 1 >= 0
                    sibs.left = siblings[myIndex - 1]
                switch event.keyCode
                    when 37     #left
                        $(sibs.left).focus() if sibs.left
                    when 38     #up
                        ''
                    when 39     #right
                        $(sibs.right).focus() if sibs.right
                    when 40     #down
                        ''
                    when 32,13      # space and return
                        $(self).click()

        $(button.getButton()).click (evt) =>
            # defunct classes also cannot be clicked
            if $(evt.currentTarget).hasClass('defunct')
                return
            if ops.selectable and not button.state.selected
                # if we click on a button and it results in the selection changing,
                # we don't want to toggle the state at all.  We just want to update
                # the display area
                @selectCourse(button)

                # trigger a focus even on ourselves so we can continue
                # using keyboard navigation from this element
                $(evt.currentTarget).focus()

                return
            # check to see if we've just been dragged by seeing if we have a noclick class
            if $(evt.currentTarget).hasClass('noclick')
                $(evt.currentTarget).removeClass('noclick')
                return
            newState = CourseManager.toggleState(button.state)
            # we need to make sure that the course appears in the yearchart if this option
            # is set
            if ops.insertOnClick
                @ensureDisplayedInYearChart(button)
            @updateCourseState(button, newState)
    makeCourseButtonDraggable: (button, ops={}) ->
        $(button.getButton()).draggable
            appendTo: 'body'
            helper: 'clone'
            revert: 'invalid'
            distance: '25'
            opacity: 0.7

    # makes the drop area of an ElectivesButton a drop target. If
    # clone is truthy instead of moving the course, a copy of the
    # course will be created.
    makeElectivesButtonDroppable: (button, ops={clone: false}) ->
        button.getButton()
        button.$coursesDiv.droppable
            #TODO this seems to mess up the parent sometimes!
            greedy: true
            hoverClass: 'highlight'
            drop: (event, ui) =>
                button.addCourse(ui.draggable[0].course)
                # calling the courseMoved method will ensure that
                # all electivesButtons are synced up and updated with
                # their new contents
                @courseMoved(ui.draggable[0].course)
                window.courseManager.selectCourse(ui.draggable[0].course)
                # when we drop a course on an electives block, assume
                # we want it automatically to be marked as an elective
                @updateCourseState(ui.draggable[0].course, {required:false, elective:true})

    # this method is called whenever a course changes levels or
    # gets added or removed from an elective's block
    courseMoved: (course) ->
        # see if any of our electivesButtons have changed
        # and if so, update them
        for hash,course of @sortableCourses
            if course instanceof ElectivesButton
                @updateElectivesButton(course)

    # returns a CourseStateButton for the desired course.  If the course
    # hasn't been loaded yet, it will be loaded and the CourseButton's data will
    # be updated accordingly
    createCourseStateButton: (course) ->
        # if we've already been loaded, our job is easy
        if @courseData[course]
            course = new CourseStateButton(@courseData[course], true)
        else
            # if the course hasn't been loaded, we return a functioning course
            # button whose data will be updated upon load
            course = new CourseStateButton(course)
            updateCourse = =>
                if not @courseData[course]
                    throw new Error("Course #{course} was loaded in dep. #{course.subject}, but wasn't available")
                course.update(@courseData[course])
                course.wasSynced = true
            @loadSubjectData(course.subject, updateCourse)
        @sortableCoursesStateButtons[course] = course
        @makeCourseStateButtonClickable(course)
        @addCourse(course)
        @initButtonState(course)
        return course
    # makes it so that when you click the button,
    # the appropriate state is broadcast
    makeCourseStateButtonClickable: (button) ->
        button.$elm.find('input').bind 'change', (evt) =>
            val = $(evt.currentTarget).parent().find('input:checked').val()
            if not val? or val is 'none'
                state = {required: false, elective: false}
            if val is 'required'
                state = {required: true, elective: false}
            if val is 'elective'
                state = {required: false, elective: true}
            @updateCourseState(button, state)
    # computes an updated state that cycles from none -> required -> elective -> none
    # Does not specify selected or prereq
    @toggleState: (state) ->
        ret =
            required: false
            elective: false
        if state.required
            ret.elective = true
        if state.elective
            ret.elective = false
        if not (state.required or state.elective)
            ret.required = true
        return ret
    # sets the button state to match the state of
    # the other course buttons currently being managed.
    # If the course isn't currently being managed, nothing is done
    initButtonState: (button) ->
        if not @courses[button] or @courses[button].length is 0
            return
        c = @courses[button][0]
        state = {required:c.state.required, elective:c.state.elective}
        button.setState(state, {forceUpdate: true})
    getSelectedCourses: ->
        ret = []
        for hash,list of @courses
            if list[0]?.state.required or list[0]?.state.elective
                ret.push list[0]
        return ret

    loadSubjectData: (subject, callback, force=false) ->
        if @loadedSubjects[subject] and not force
            callback()
        $.ajax
            url: "course_data/#{subject}.json"
            dataType: 'json'
            success: @courseDataLoaded
            error: (e) ->
                console.log 'ajax error'
                throw e
            complete: callback
    courseDataLoaded: (data, textState, jsXHR) =>
        for c in data
            @courseData[BasicCourse.hashCourse(c)] = c
            @loadedSubjects[c.subject] = true
    # shows courses from a particular department.  If buttons
    # already exist for the department, those buttons are made visible.
    # If not, the buttons are created
    showCoursesOfSubject: (subject) ->
        showCourses = =>
            for hash,course of @sortableCourses
                if course.subject is subject
                    course.$elm.show()
        if @loadedSubjects[subject]
            @populateYearChartWithSubject(subject)
            showCourses()
        else
            # TODO fix potential endless loop
            @loadSubjectData(subject, => @showCoursesOfSubject(subject))
        return
    # hide all courses from a particular department
    # that aren't marked as required or as an elective
    hideCoursesOfSubject: (subject) ->
        for hash,course of @sortableCourses
            if course.subject is subject and course.state.required is false and course.state.elective is false
                if course.elm
                    course.$elm.hide()
        return
    populateYearChartWithSubject: (subject) ->
        years = {}
        for hash,data of @courseData
            # find everything of match subject for which a button hasn't already been created
            if data.subject is subject and not @sortableCourses[hash]
                leadingNumber = data.number.charAt(0)
                years[leadingNumber] = years[leadingNumber] || []
                years[leadingNumber].push data
        for year in ['1','2','3','4']
            list = years[year] || []
            list.sort()
            container = $(".year#{year} .courses")
            for data in list
                course = @createCourseButton(data, {clickable: true, selectable: true, draggable: true})
                #course.$elm.hide()
                @sortableCourses[course] = course
                container.append(course.getButton())
        return
    ensureDisplayedInYearChart: (course) ->
        hash = BasicCourse.hashCourse(course)
        # this is a course that cannot be added since it doesn't exist in a subject
        if not @courseData[hash] and @loadedSubjects[course.subject]
            throw new Error("#{hash} cannot be loaded.  Does not appear to exist...")
        if not @courseData[hash]
            @loadSubjectData(course.subject, => @ensureDisplayedInYearChart(course))

        if @sortableCourses[hash]
            @sortableCourses[hash].$elm.show()
            return
        leadingNumber = @courseData[hash].number.charAt(0)
        if leadingNumber in ['1','2','3','4']
            course = @createCourseButton(@courseData[hash], {clickable: true, selectable: true, draggable: true})
            @sortableCourses[course] = course
            $(".year#{leadingNumber} .courses").append(course.getButton())
    showUnmetPrereqs: ->
        # we need a list of courses that are required or electives to find their prereqs
        activeCourses = []
        for hash, course of @sortableCourses
            if course.state.required or course.state.elective
                activeCourses.push course
        prereqs = PrereqUtils.computePrereqTree(activeCourses, activeCourses)
        div = PrereqUtils.prereqsToDivs(prereqs, @)
        $('#unmet-prereq-list').html div

    # returns a string formatted in graphviz's dot language
    # consisting of all the selected courses of each year and
    # with prereqs given by arrows
    createDotGraph: ->
        # returns whether or not a single course should be inlcuded in the graph
        # and if given a list, will filter the list so only courses that should be displayed remain
        filterDisplayable = (list) ->
            if not list
                return list
            if not list.length?
                return list.state?.required or list.state?.elective
            return (c for c in list when filterDisplayable(c))

        clusters = []
        # get a list of courses by year
        years = {1:[],2:[],3:[],4:[]}
        for i in [1, 2, 3, 4]
            elms = $(".year#{i} .courses").children()
            for e in elms
                subject = e.getAttribute('subject')
                number = e.getAttribute('number')
                hash = BasicCourse.hashCourse({subject:subject, number:number})
                if @sortableCourses[hash] instanceof Electives
                    years[i] = years[i].concat(filterDisplayable(objValsToArray(@sortableCourses[hash].courses)))
                    clusters.push {year: i, info: @sortableCourses[hash], nodes:filterDisplayable(objValsToArray(@sortableCourses[hash].courses))}
                if filterDisplayable(@sortableCourses[hash])
                    years[i].push @sortableCourses[hash]

        allCourses = years[1].concat(years[2]).concat(years[3]).concat(years[4])
        allCoursesHash = (c.hash for c in allCourses)
        # put the display courses in a hash table for quick lookup
        courseHashLookup = {}
        for hash in allCoursesHash
            courseHashLookup[hash] = true

        # find all edges given by prerequisites
        edges = []
        for course in allCourses
            if course.prereqs?
                prereqs = (BasicCourse.hashCourse(c) for c in PrereqUtils.flattenPrereqs(course.prereqs))
                for p in prereqs
                    if courseHashLookup[p]
                        edges.push [p, course.hash]

        # put the info into a graph so we can do some pruning operations
        g = new DiGraph(edges, allCourses)
        g.years = years
        # prune the edges in the graph to prefer longer
        # prereq chains to shorter ones
        titles = {}
        for t of g.nodes
            titles[t] = titleCaps((''+@sortableCourses[t].data.title).toLowerCase())
        $('#dot2').val g.toDot('unpruned', titles, clusters, {title:$('#program-info input').val()})
        console.log g.eliminateRedundantEdges()
        return g.toDot('pruned', titles, clusters, {title:$('#program-info input').val()})


###
# Utility functions for dealing with lists of courses and their prereqs
###
CourseUtils =
    # adds the prereq class to all class buttons
    # that are an unsatisfied prereq of any class currently selected
    updatePrereqTags: ->
        selected = CourseUtils.getSelectedCourses()
        prereqs = CourseUtils.computePrereqTree(selected, selected)
        unmet = {}
        for c in Course.flattenPrereqs(prereqs)
            unmet[Course.hashCourse(c)] = true
        for hash,c of window.courses
            c.setState({prereq: !!unmet[hash]})

        console.log (k for k of unmet).join(' ')
        return unmet

PrereqUtils =
    prereqsToString: (prereq) ->
        if not prereq?
            return ""
        if prereq.subject
            return Course.hashCourse(prereq)
        if prereq.op
            # only give a pretty result if our data is formatted correctly
            if typeof prereq.op is 'string'
                return "(" + (PrereqUtils.prereqsToString(p) for p in prereq.data).join(" #{prereq.op} ") + ")"
            else
                return ""
        return
    # returns the prereq pruned so that any branches whose
    # requirements are met are no longer there
    # courses should be a list of course hashes
    prunePrereqs: (prereq, courses) ->
        if not prereq?
            throw new Error("Yikes.  We errored while pruning the prereqs!")

        ret = {op: 'and', data: []}
        if prereq.subject
            if courses.indexOf(BasicCourse.hashCourse(prereq)) is -1
                ret.data.push prereq
        switch prereq.op
            when 'or'
                ret.op = 'or'
                for course in prereq.data
                    # if we're in an 'or' list and we've found one of our items,
                    # we're done!  Return an empty list
                    prunedBranch = PrereqUtils.prunePrereqs(course, courses)
                    if prunedBranch.data?.length == 0
                        return {op: 'and', data: []}
                    # if our branch isn't empty, we better keep it around
                    ret.data.push prunedBranch
            when 'and'
                for course in prereq.data
                    # if we're in an 'and' list, we need to keep any branches
                    # that have not been fully met
                    prunedBranch = PrereqUtils.prunePrereqs(course, courses)
                    if prunedBranch.data?.length != 0
                        # if our branch isn't empty, we better keep it around
                        ret.data.push prunedBranch
        return ret
    # Takes prereq object and simplifies it by remove unnecessary 'parens'
    # eg. (MATH100) and (MATH101) -> MATH100 and MATH101
    simplifyPrereqs: (prereq) ->
        removeParen = (prereq) ->
            if not prereq.data?
                return prereq
            if prereq.data.length == 1
                return removeParen(prereq.data[0])
            return {op: prereq.op, data: (removeParen(p) for p in prereq.data)}
        return removeParen(prereq)
    # returns a flat list of all prereqs.
    flattenPrereqs: (prereq) ->
        if prereq?.subject
            return [prereq]
        if prereq?.op
            ret = []
            for c in prereq.data
                ret = ret.concat(PrereqUtils.flattenPrereqs(c))
            return ret
        return []

    # creates a dom element with all the prereqs as buttons synced with manager (instace of CourseManager)
    prereqsToDivs: (prereq, manager) ->
        # create a string representing the dom structure
        prereqsToDivs = (prereq) ->
            if not prereq?
                return ""
            if prereq.subject
                hash = BasicCourse.hashCourse(prereq)
                return "<course id='#{hash}' subject='#{prereq.subject}' number='#{prereq.number}'>#{hash}</course>"
            if prereq.op
                # only give a pretty result if our data is formatted correctly
                if typeof prereq.op is 'string'
                    return "<ul class='prereq-tree prereq-#{prereq.op}'><li class='prereq-tree prereq-#{prereq.op}'>" + (prereqsToDivs(p) for p in prereq.data).join("</li><li class='prereq-tree prereq-#{prereq.op}'>") + "</ul>"
                else
                    return ""
            return
        # first create the structure for all the prereqs.  We will then go and replace
        # all the <course/> tags with CourseButton s if a manager (CourseManager) is present.
        # We wrap everything in an extra div so that jQuery.find('course') will find the course
        # tag even if prereqsToDivs returns "<course />" (also, this ensures every <course/> has
        # a parent)
        divs = $("<div>#{prereqsToDivs(prereq)}</div>")
        if not manager
            return divs
        for elm in divs.find('course')
            subject = elm.getAttribute('subject')
            number = elm.getAttribute('number')
            course = manager.createCourseButton({subject:subject, number:number}, {clickable:true, insertOnClick:true})
            courseElm = course.getButton()
            elm.parentNode.replaceChild(courseElm, elm)
        return divs
    # given a list of courses and a list of selected courses, returns a tree of prereqs
    # unmet by the selected courses
    computePrereqTree: (courses, selected=[]) ->
        if not courses?
            throw new Error("computePrereqTree requires a list of course hashes")
        # selected should be a list of hashes, so if it's not, convert it!
        hashify = (s) ->
            if typeof s is 'string'
                return s
            return BasicCourse.hashCourse(s)
        selected = (hashify(s) for s in selected)
        ret = {op: 'and', data: []}
        for course in courses
            if typeof course is 'string'
                throw new Error("cannot computePrereqTree with courses given as strings")
            if not course.wasSynced
                throw new Error("attempting to compute prereqs of #{course} when data isn't synced")
            if course.prereqs?
                pruned = PrereqUtils.prunePrereqs(course.prereqs, selected)
                if pruned.data?.length > 0
                    # tag this branch of prereqs so that we know who requires it
                    pruned.requiredBy = course
                    ret.data.push pruned
        ret = PrereqUtils.simplifyPrereqs(ret)
        return ret

###
# Parent class of various course buttons
###
class BasicCourse
    @hashCourse: (course) ->
        return "#{course.subject} #{course.number}"
    constructor: (@data, synced=false) ->
        @hash = BasicCourse.hashCourse(@data)
        {@subject, @number, @prereqs} = @data
        @state =
            required: false
            elective: false
            selected: false
            prereq: false
        @wasSynced = synced  # false if the course only has @subject and @number, true if it has the rest of the course details
    toString: ->
        return @hash
    update: (@data) ->
        @prereqs = @data.prereqs

    # set the course's state and return only
    # the items in the state that changed
    setState: (state) ->
        ret = {}
        for s,v of state
            if @state[s] != v
                ret[s] = v
                @state[s] = v
        return ret

###
# Rectangular button that displays a course's number and state
###
class CourseButton extends BasicCourse
    constructor: (data) ->
        super(data)
        @getButton()
    setState: (state, ops={}) ->
        changedState = super(state)
        if not ops.forceUpdate
            state = changedState
        # update the classes on the button if it exists
        if not @elm
            return state
        for s,v of state
            if v
                @$elm.addClass(s)
            else
                @$elm.removeClass(s)
        return state
    getButton: ->
        if @elm
            return @elm
        @$elm = $("<div class='course' subject='#{@subject}' number='#{@number}'><div class='annotation'></div><div class='number'>#{@subject} #{@number}</div></div>")
        @$elm.disableSelection()
        @elm = @$elm[0]
        @elm.course = @
        # make sure to initialize the state.  We may have changed it before we created the button element!
        @setState(@state)
        return @elm
    removeButton: ->
        if not @elm
            return
        @elm.course = null  #make sure we remove the circular ref so we can be garbage collected
        @$elm.remove()
        @elm = @$elm = null
###
# Set of three toggle buttons that change (and reflect) the state of a course
###
class CourseStateButton extends BasicCourse
    constructor: (data) ->
        super(data)
        @getButton()
    getButton: ->
        if @elm
            return @elm
        @$elm = $("""<div class='course-status'>
                <input type='radio' name='state' value='none' id='course-notincluded' /><label for='course-notincluded'>Not Included</label>
                <input type='radio' name='state' value='required' id='course-required' /><label for='course-required'>Required</label>
                <input type='radio' name='state' value='elective' id='course-elective' /><label for='course-elective'>Elective</label>
        </div>""")
        @$elm.buttonset()
        @elm = @$elm[0]
    setState: (state, ops={}) ->
        changedState = super(state)
        if not ops.forceUpdate
            state = changedState
        # update the classes on the button if it exists
        if (not @elm or Object.keys(state).length is 0) and not ops.forceUpdate
            return state
        @$elm.find('input').attr('checked', false)
        if @state.required
            @$elm.find('input[value=required]').attr('checked', true)
        else if @state.elective
            @$elm.find('input[value=elective]').attr('checked', true)
        else
            @$elm.find('input[value=none]').attr('checked', true)
        #@$elm.buttonset('refresh')
        #TODO I don't know why i need to do this...
        window.setTimeout((=> @$elm.buttonset('refresh')), 0)

        return state
    removeButton: ->
        if not @elm
            return
        @elm.course = null  #make sure we remove the circular ref so we can be garbage collected
        @$elm.remove()
        @elm = @$elm = null
###
# Holds a group of courses
###
class Electives
    constructor: (data) ->
        {@title, @requirements, @number} = data
        # make sure we don't just use the courses object that was passed in,
        # we want to shallow copy so we actually have an internal copy!
        @courses = dupObject(data.courses || {})

        @state = {}
        if not @requirements?
            @requirements={units:1.5, unitLabel:'units'}
        @subject = @title
        @number = @number || Math.random().toFixed(8) # give us a random number so we never hash-collide with other electives blocks with the same name
        @hash = BasicCourse.hashCourse(@)
    toString: ->
        return @hash
    addCourse: (course) ->
        @courses[course] = course
    removeCourse: (course) ->
        delete @courses[course]
    setState: (state) ->
        ret = {}
        for s,v of state
            if @state[s] != v
                ret[s] = v
                @state[s] = v
        return ret
    update: (data) ->
        for k,v of data
            @[k] = v
        # we'd like to keep the subject fixed for hashing purposes
        #@subject = @title
        @hash = BasicCourse.hashCourse(@)
    getValues: ->
        return {@title, @requirements, @number, @courses}

class ElectivesButton extends Electives
    constructor: (data, @manager) ->
        super(data)
        @getButton()
    setState: (state, ops={}) ->
        changedState = super(state)
        if not ops.forceUpdate
            state = changedState
        # update the classes on the button if it exists
        if not @elm
            return state
        for s,v of state
            if v
                @$elm.addClass(s)
            else
                @$elm.removeClass(s)
        return state
    getButton: ->
        if @elm
            return @elm
        @$elm = $("""<div class="electives-block" subject="#{@subject}" number="#{@number}">
		<div class="title">#{@title}</div>
		<div class="requirement">At least #{@requirements.units} #{@requirements.unitLabel}</div>
		<div class="courses-list"><span class="droptext">Drop Here to Add Courses</span></div>
	</div>""")
        @elm = @$elm[0]
        @$coursesDiv = @$elm.find('.courses-list')

        # populate with all the courses in our course list, creating buttons
        # if they have none
        for hash,course of @courses
            @addCourse(course)
        return @elm

    addCourse: (course) ->
        super(course)
        if not course.elm
            course = @courses[BasicCourse.hashCourse(course)] = new CourseButton(course.data)
        @$coursesDiv.append(course.elm)
        @updateDropTextVisibility()

    removeCourse: (course, ops={detach: true}) ->
        if ops.detach
            $elm = @courses[BasicCourse.hashCourse(course)].$elm
            $elm.detach() if $elm
        super(course)
        @updateDropTextVisibility()
    update: (data) ->
        super(data)
        # make soure our internal courses list is up to date
        @courses = {}
        for elm in @$elm.find('.courses-list').children()
            if elm.course
                @courses[elm.course] = elm.course
        @$elm.find('.title').html @title
        @$elm.find('.requirement').html "At least #{@requirements.units} #{@requirements.unitLabel}"
        @$elm.attr({@subject, @number})
        @updateDropTextVisibility()
    # hides the drop text if we have children and shows it otherwise
    updateDropTextVisibility: ->
        if Object.keys(@courses).length == 0
            @$elm.find('.droptext').show()
        else
            @$elm.find('.droptext').hide()

class ElectivesButtonEditor extends Electives
    constructor: (data, @manager) ->
        super(data)
        @getButton()
    setState: (state, ops={}) ->
        changedState = super(state)
        if not ops.forceUpdate
            state = changedState
        # update the classes on the button if it exists
        if not @elm
            return state
        for s,v of state
            if v
                @$elm.addClass(s)
            else
                @$elm.removeClass(s)
        return state
    getButton: ->
        if @elm
            return @elm
        @$elm = $("""<div class='elective-editable'>
                    <div class='title'>Title: <input type='text' value='#{@title}'></input></div>
                    <div class='requirements'>At least <input type='text' value='#{@requirements.units}'></input> #{@requirements.unitLabel}</div>
                    Elective Courses: <div class='dropbox courses-list'><span class='droptext'>Use the Year Chart to Add Courses</span></div>
                </div>""")
        @elm = @$elm[0]
        @$coursesDiv = @$elm.find('.courses-list')

        # populate with all the courses in our course list, creating buttons
        # if they have none
        for hash,course of @courses
            @addCourse(course)

        # set up callbacks for when we've been edited
        update = (event) =>
            if @manager
                @manager.updateElectivesButton(@)
        @$elm.find('.title input').change update
        @$elm.find('.requirements input').change update

        return @elm

    addCourse: (course) ->
        super(course)
        if not course.elm
            course = @courses[BasicCourse.hashCourse(course)] = new CourseButton(course.data)
        @$coursesDiv.append(course.elm)
        @updateDropTextVisibility()

    removeCourse: (course, ops={detach: true}) ->
        if ops.detach
            $elm = @courses[BasicCourse.hashCourse(course)].$elm
            $elm.detach() if $elm
        super(course)
        @updateDropTextVisibility()
    update: (data) ->
        super(data)
        @$elm.find('.title input').val @title
        @$elm.find('.requirements .input').val @requirements.units
        @updateDropTextVisibility()
    # returns the values of @title and @requirement, updating
    # them if they differ from the values in @elm
    getValues: ->
        @title = @$elm.find('.title input').val()
        @requirements.units = @$elm.find('.requirements input').val()
        return super()
    # hides the drop text if we have children and shows it otherwise
    updateDropTextVisibility: ->
        if Object.keys(@courses).length == 0
            @$elm.find('.droptext').show()
        else
            @$elm.find('.droptext').hide()


###
# Class to perform operations on a directed graph like
# searching for multiple paths, finding neighbors, etc.
###
class DiGraph
    constructor: (edges, nodes=[]) ->
        @nodes = {}
        @edges = []
        @forwardNeighborHash = null
        @backwardNeighborHash = null

        for n in nodes
            @nodes[n] = true
        for e in edges
            @edges.push e.slice()
            @nodes[e[0]] = true
            @nodes[e[1]] = true
    _generateForwardNeighborHash: ->
        if @forwardNeighborHash
            return

        hash = {}
        for e in @edges
            if not hash[e[0]]?
                hash[e[0]] = []
            hash[e[0]].push e[1]
        @forwardNeighborHash = hash
    _generateBackwardNeighborHash: ->
        if @backwardNeighborHash
            return

        hash = {}
        for e in @edges
            if not hash[e[1]]?
                hash[e[1]] = []
            hash[e[1]].push e[0]
        @backwardNeighborHash = hash
    # computes all the nodes in the span of edge
    edgeSpan: (node) ->
        ret = {}
        @_generateForwardNeighborHash()

        maxDepth = Object.keys(@nodes).length

        findNeighbors = (node, depth) =>
            ret = []
            if depth >= maxDepth or not node? or not @forwardNeighborHash[node]?
                return ret
            for l in @forwardNeighborHash[node]
                ret = ret.concat(findNeighbors(l, depth + 1))
            return ret.concat(@forwardNeighborHash[node])

        return findNeighbors(node, 0)

    # determines if there is a path between e1 and e2
    isPath:(n1, n2) ->
        return @edgeSpan(n1).indexOf(n2) != -1 or @edgeSpan(n2).indexOf(n1) != -1

    # looks at all the ancestors of node and sees if there are alternative,
    # longer routes to node.  If so, it deletes the edge between node and
    # the anscestor.
    #
    # return the number of edges deleted
    eliminateRedundantEdgesToNode: (node) ->
        @_generateBackwardNeighborHash()
        @_generateForwardNeighborHash()
        ancestors = @backwardNeighborHash[node] || []

        for n in ancestors
            span = @edgeSpan(n)
            spanHash = {}
            for s in span
                spanHash[s] = true
            for s in ancestors
                # we want to loop through all of our siblings that aren't us
                if s == n
                    continue
                # if we can get from n -> s and we know there is an edge from s -> node,
                # then we can safely delete the edge n -> s
                if spanHash[s]
                    @removeEdge([n,node])
                    return 1 + @eliminateRedundantEdgesToNode(node)
        return 0

    # eliminates short paths to between nodes if there is a longer path
    # connecting them
    #
    # TODO is there a more efficient way to do this?  This should be ok for small graphs but
    # bad for large ones.
    eliminateRedundantEdges: ->
        ret = 0
        for n of @nodes
            ret += @eliminateRedundantEdgesToNode(n)
        return ret

    # removes the edge edge
    removeEdge: (edge) ->
        # get a list of all the edges we're going to remove
        # we want the list to be in reverse numberial order so
        # as we splice away the edges, things work out
        indices = []
        for e,i in @edges
            if DiGraph.edgesEqual(e, edge)
                indices.unshift i
        for i in indices
            @edges.splice(i, 1)
        # these hashs are now invalid!
        @forwardNeighborHash = null
        @backwardNeighborHash = null

    @edgesEqual: (e1, e2) ->
        return (e1[0] == e2[0]) and (e1[1] == e2[1])

    # finds the forward neighbors of all vertices in subgraphNodes.
    # Vertices in subgraphnodes are not included in this list
    findForwardNeighborsOfSubgraph: (subgraphNodes) ->
        # ensure we are working with a dictionary
        if subgraphNodes instanceof Array
            nodes = subgraphNodes
            subgraphNodes = {}
            for n in nodes
                subgraphNodes[n] = true

        @_generateForwardNeighborHash()
        ret = {}
        for n of subgraphNodes
            for child in (@forwardNeighborHash[n] || [])
                if not subgraphNodes[child]
                    ret[child] = true
        return ret
    # finds the forward neighbors of all vertices in subgraphNodes.
    # Vertices in subgraphnodes are not included in this list
    findBackwardNeighborsOfSubgraph: (subgraphNodes) ->
        # ensure we are working with a dictionary
        if subgraphNodes instanceof Array
            nodes = subgraphNodes
            subgraphNodes = {}
            for n in nodes
                subgraphNodes[n] = true

        @_generateBackwardNeighborHash()
        ret = {}
        for n of subgraphNodes
            for child in (@backwardNeighborHash[n] || [])
                if not subgraphNodes[child]
                    ret[child] = true
        return ret
    # returns a list containing every source node
    findSources: ->
        ret = []
        @_generateBackwardNeighborHash
        for n of @nodes
            if not @backwardNeighborHash[n]
                ret.push n
        return ret
    # given a list of nodes, breakIntoTerms will attempt
    # to split them into at most maxTerms number of levels based
    # on arrow direction and returns the stratification.
    # e.g. "a->b->c, d" would split into [a,d] then [b] then [c]
    breakIntoTerms: (list, maxTerms=3) ->
        @_generateForwardNeighborHash()
        ranks = {}
        updateRanks = (updateHash) =>
            for k of ranks
                if updateHash[k]
                    ranks[k] += 1
            return
        giveNodesOfRank = (rank) =>
            return (n for n,v of ranks when v == rank)
        getForwardNeighbordsOfRank = (rank) =>
            forwardNeighbors = {}
            for c in giveNodesOfRank(rank)
                for n in (@forwardNeighborHash[c]|| [])
                    forwardNeighbors[n] = true
            return forwardNeighbors

        # initialize all ranks
        for c in list
            ranks[c] = 0
        # bump up the ranks of things iteratively
        for i in [0...maxTerms-1]
            forwardNeighbors = getForwardNeighbordsOfRank(i)
            updateRanks(forwardNeighbors)
        ret = []
        for i in [0..maxTerms]
            nodes = giveNodesOfRank(i)
            ret.push nodes if nodes.length > 0
        return ret


    # returns a string representing the graph in
    # graphviz dot format
    toDot: (name, titles={}, clusters=[], ops={}) ->
        ret = "digraph #{name} {\n"
        ret += "\trankdir=LR\n"

        # put each of the clusters as subgraphs.  This needs to be done first
        # so these nodes get the appropriate style
        clusterYears = {1:[], 2:[], 3:[], 4:[]}
        for clust,i in clusters
            # if the cluster has no children, we make it a special node instead
            if (clust.nodes || []).length is 0
                nodeId = 'clust' + Math.random().toFixed(8).slice(2)
                ret += "\t#{nodeId} [style=\"rounded,filled\", shape=box, color=invis, fillcolor=gray, "
                ret += """label=<#{htmlEncode(clust.info.title)} """
                ret += """(At least #{htmlEncode(clust.info.requirements.units)} #{clust.info.requirements.unitLabel})>]\n"""
                clusterYears[clust.year].push nodeId
            else
                ret += "\tsubgraph cluster#{i} {\n"
                # node styles
                ret += "\tnode [shape=box,style=\"rounded,filled\",color=white]\n"
                # cluster styles
                ret += "\t\tstyle=\"rounded,filled\"\n"
                ret += "\t\tcolor=gray\n"
                ret += """\t\tlabel=<<table><tr><td align="left">#{htmlEncode(clust.info.title)}</td>"""
                ret += """<td align="right">(At least #{htmlEncode(clust.info.requirements.units)} #{clust.info.requirements.unitLabel})</td></tr></table>>\n"""
                console.log clust
                for c in clust.nodes
                    ret += "\t\t\"#{htmlEncode(c.hash)}\"\n" #[label=<<font color=\"red\">#{c.hash}</font><br/><font color=\"blue\">#{titles[c]}</font>>]\n"
                ret += "\t}\n"

        ret += "\n"
        ret += "\tnode [shape=box,style=rounded]\n"
        for e in @edges
            ret += "\t\"#{e[0]}\" -> \"#{e[1]}\"\n"
        ret += "\n"

        # ensure classes of each year appear on the proper rank
        for i in [1, 2, 3, 4]
            if @years
                ret += "\tsubgraph year#{i} {\n"
                for clust in @breakIntoTerms (c.hash for c in @years[i])
                    ret += "\t\tsubgraph {\n"
                    ret += "\t\t\trank=same\n"
                    for c,j in clust
                        ret += "\t\t\t\"#{c}\" [label=<<font color=\"red\">#{c}</font><br/><font color=\"blue\">#{titles[c]}</font>>]\n"
                        # empty clusers were turned into nodes.  These nodes have already
                        # had their label set, so we just need to include them in the appropriate year
                        if j == 0
                            for n in clusterYears[i]
                                ret += "\t\t\t#{n}\n"
                    ret += "\t\t}\n"
                #ret += "\t\trank=same\n"
                #ret += "\t\tlabel=\"Year #{i}\"\n"
                #for c in @years[i]
                #    ret += "\t\t\t\"#{c.hash}\" [label=<<font color=\"red\">#{c.hash}</font><br/><font color=\"blue\">#{titles[c]}</font>>]\n"
                ret += "\n\t}\n"

        # put the title last so it doesn't try to apply to all subgraphs
        if ops.title
            ret += "\tlabel=<<font point-size=\"30\">#{ops.title}</font>>\n"
            ret += "\tlabelloc=t\n" #label position top
        ret += "}"

        return ret
