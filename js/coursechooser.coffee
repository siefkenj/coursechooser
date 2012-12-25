objToString = (obj) ->
    ret = '{ '
    for p,v of obj
        ret += " #{p}:#{v}, "
    return ret + "}"

###
# * Title Caps
# *
# * Ported to JavaScript By John Resig - http://ejohn.org/ - 21 May 2008
# * Original by John Gruber - http://daringfireball.net/ - 10 May 2008
# * License: http://www.opensource.org/licenses/mit-license.php
###
titleCaps = (->
    lower = (word) ->
        word.toLowerCase()
    upper = (word) ->
        word.substr(0, 1).toUpperCase() + word.substr(1)
    small = "(a|an|and|as|at|but|by|en|for|if|in|of|on|or|the|to|v[.]?|via|vs[.]?|with)"
    punct = "([!\"#$%&'()*+,./:;<=>?@[\\\\\\]^_`{|}~-]*)"
    titleCaps = (title) ->
        parts = []
        split = /[:.;?!] |(?: |^)["Ò]/g
        index = 0
        loop
            m = split.exec(title)
            parts.push title.substring(index, (if m then m.index else title.length)).replace(/\b([A-Za-z][a-z.'Õ]*)\b/g, (all) ->
                (if /[A-Za-z]\.[A-Za-z]/.test(all) then all else upper(all))
            # capitalize roman numerals
            ).replace(/\b(i|v|x|l|c|d|m)+\b/i, (all) ->
                all.toUpperCase()
            ).replace(RegExp("\\b" + small + "\\b", "ig"), lower).replace(RegExp("^" + punct + small + "\\b", "ig"), (all, punct, word) ->
                punct + upper(word)
            ).replace(RegExp("\\b" + small + punct + "$", "ig"), upper
            )
            index = split.lastIndex
            if m
                parts.push m[0]
            else
                break
        parts.join("").replace(RegExp(" V(s?)\\. ", "g"), " v$1. ").replace(/(['Õ])S\b/g, "$1s").replace /\b(AT&T|Q&A)\b/g, (all) ->
            all.toUpperCase()
    return titleCaps
)()
$(document).ready ->
    ###
    $.ajax
        url: 'MATH_items.json'
        dataType: 'json'
        success: courseDataLoaded
    ###
    $('.course-status').buttonset().disableSelection()
    $('button').button()

    showCoursesFromDep('MATH')
    $('#show-courses').click ->
        dep = $('#department-list option:selected()').val()
        showCoursesFromDep(dep)
    $('#hide-courses').click ->
        dep = $('#department-list option:selected()').val()
        hideCoursesFromDep(dep)

window.courses = {}

# shows courses from a particular department.  If buttons
# already exist for the department, those buttons are made visible.
# If not, the buttons are created
showCoursesFromDep = (dep) ->
    # create a list of all departments that already have buttons
    buttonsToBeCreated = {}
    courseDataNeedsLoading = true
    for hash, course of window.courses
        if course.subject is dep
            # if we've found a course already in our list, we don't need to fetch it from json
            courseDataNeedsLoading = false
            if course.elm
                course.$elm.show()
            else
                buttonsToBeCreated[hash] = course
    populateYearTable(buttonsToBeCreated)

    if courseDataNeedsLoading
        # we need to load the json corresponding to the course
        $.ajax
            url: "course_data/#{dep}.json"
            dataType: 'json'
            success: courseDataLoaded

# hide all courses from a particular department
# that aren't marked as required or as an elective
hideCoursesFromDep = (dep) ->
    for hash, course of window.courses
        if course.subject is dep and course.state.required is false and course.state.elective is false
            if course.elm
                course.$elm.hide()


courseDataLoaded = (data, textState, jsXHR) ->
    # set up a global list of all courses by name
    for c in data
        course = new Course(c)
        window.courses[course.hash] = course

    populateYearTable(window.courses)

    # make all the buttons draggable
    $('.courses').sortable(
        connectWith: '.courses'
        distance: 25
        deactivate: (event, ui) ->
            # if we've just been dragged, we don't want a click event fired
            ui.item.addClass('noclick')
    ).disableSelection()
    # make all the buttons clickable
    for elm in $('.course')
        if not elm.course.bound
            elm.course.bound = true
            $(elm).click (evt) ->
                # make sure nobody else is selected but us
                for hash, course of window.courses
                    course.setState({selected: false})
                evt.currentTarget.course.setState({selected: true})
                # check to see if we've just been dragged by seeing if we have a noclick class
                if $(evt.currentTarget).hasClass('noclick')
                    $(evt.currentTarget).removeClass('noclick')
                    return
                evt.currentTarget.course.toggleState()
                # make sure to do this after the state has been set, otherwise prereqs won't
                # be computed correctly
                CourseUtils.updatePrereqTags()
                evt.currentTarget.course.showCourseInfo($('.course-info')[0])
                $("#dot").val CourseUtils.createDotGraph()

populateYearTable = (courses) ->
    # create a list of courses for each year (based on the first digit of the course number
    years = {}
    for k,c of courses
        year = c.number.charAt(0)
        if not years[year]?
            years[year] = []
        years[year].push [c.hash, c]

    # sort the course lists and show years 1-4
    for year,list of years
        if year in ['1','2','3','4']
            list.sort()
            container = $(".year#{year} .courses")
            for [hash, course] in list
                container.append(course.getButton())

###
# Class to manage and keep the sync of all course on the webpage
# and their state.
###
class CourseManager
    constructor: ->
        @courses = {}
    # updates the state of all instances of a particular course
    updateCourseState: (course, state) ->
        for c in (@courses[course] || [])
            c.setState(state)
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

###
# Utility functions for dealing with lists of courses and their prereqs
###
CourseUtils =
    computePrereqTree: (courses, selected=[]) ->
        if not courses?
            throw new Error("computePrereqTree requires a list of course hash's")
        ret = {op: 'and', data: []}
        for hash in courses
            course = window.courses[hash]
            if course.prereqs?
                pruned = Course.prunePrereqs(course.prereqs, selected)
                pruned = Course.simplifyPrereqs(pruned)
                if pruned.data?.length > 0
                    # tag this branch of prereqs so that we know who requires it
                    pruned.requiredBy = course
                    ret.data.push pruned
        return ret

    getSelectedCourses: ->
        return (hash for hash,c of window.courses when c.state.required or c.state.elective)

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

    createDotGraph: ->
        # get a list of courses by year
        years = {1:[],2:[],3:[],4:[]}
        for i in [1, 2, 3, 4]
            elms = $(".year#{i} .courses").children()
            for e in elms
                years[i].push e.course if (e.course.state.required || e.course.state.elective)
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
                prereqs = (Course.hashCourse(c) for c in Course.flattenPrereqs(course.prereqs))
                for p in prereqs
                    if courseHashLookup[p]
                        edges.push [p, course.hash]

        # put the info into a graph so we can do some pruning operations
        g = new DiGraph(edges, allCourses)
        g.years = years
        # prune the edges in the graph to prefer longer
        # prereq chains to shorter ones
        ret = g.toDot('unpruned') + "\n"
        console.log g.eliminateRedundantEdges()
        titles = {}
        for t of g.nodes
            titles[t] = titleCaps((window.courses[t].data.title+"").toLowerCase())
        return g.toDot('pruned', titles)

###
# Object to store course info along with managing a button
# relating to a particular course and all of its state,
# prereqs, etc.
###
class Course
    @hashCourse: (course) ->
        return "#{course.subject} #{course.number}"

    constructor: (@data) ->
        @hash = Course.hashCourse(@data)
        {@subject, @number, @prereqs} = @data
        @elm = null
        @state =
            required: false
            elective: false
            selected: false
            prereq: false
    toString: ->
        return @hash
    # list of functions to be called each time setState is called
    setStateCallbacks: []
    getButton: ->
        if @elm
            return @elm

        @$elm = $("<div class='course'><div class='annotation'></div><div class='number'>#{@subject} #{@number}</div></div>")
        @elm = @$elm[0]
        @elm.course = @
        # make sure to initialize the state.  We may have changed it before we created the button element!
        @setState(@state)
        return @elm

    # Set all neccessary classes and update internal state based on the object state
    setState: (state={}, forceUpdate=false) ->
        stateChanged = forceUpdate
        for k,s of state
            if @state[k] != s or forceUpdate
                stateChanged = true
                @state[k] = s
                if s
                    @$elm?.addClass(k)
                else
                    @$elm?.removeClass(k)
        # call all of our callbacks
        if stateChanged
            for f in @setStateCallbacks
                f()
        return
    # Cycle the state from none -> required -> elective -> none
    toggleState: ->
        state =
            required: false
            elective: false
        if @state.required
            state.elective = true
        if @state.elective
            state.elective = false
        if not (@state.required or @state.elective)
            state.required = true

        @setState(state)
        return
    # display all the course information in the specified infoarea
    showCourseInfo: (infoarea) ->
        $infoarea = $(infoarea)
        $infoarea.find('.course-name').html "#{@hash} &mdash; #{@data.title}"
        $infoarea.find('.prereq-area').html Course.prereqsToDivs(@prereqs)
        #$infoarea.find('.prereq-area').html Course.prereqsToDivs(CourseUtils.computePrereqTree(CourseUtils.getSelectedCourses()))

        # make sure to unbind the previous course before we bind ourselves
        @unbindRadioButtons(infoarea)
        @bindRadioButtons(infoarea)

        # force an update of the state since we now should be displayed
        @setState({}, true)
    # bind to the state radio buttons in infoarea.  When the course state is
    # changed, the radio buttons will be changed and when the radio buttons
    # are changed, the state will be changed
    bindRadioButtons: (infoarea) ->
        # bound function that will change our state when the toggle buttons change
        changeState = (evt) =>
            val = $(evt.currentTarget).parent().find('input:checked').val()
            if not val? or val is 'none'
                @setState({required: false, elective: false})
            if val is 'required'
                @setState({required: true, elective: false})
            if val is 'elective'
                @setState({required: false, elective: true})
        # we need to rember our bound function so we can unbind it later
        infoarea.boundRadioFunction = changeState
        $(infoarea).find('input').bind('change', changeState)

        changeToggle = =>
            $(infoarea).find('input').attr('checked', false)
            if @state.required
                $(infoarea).find('input[value=required]').attr('checked', true)
            else if @state.elective
                $(infoarea).find('input[value=elective]').attr('checked', true)
            else
                $(infoarea).find('input[value=none]').attr('checked', true)
            try
                $('.course-status').buttonset('refresh')
            catch e

        @setStateCallbacks.push changeToggle
        infoarea.boundChangeToggle = [@, changeToggle]

    unbindRadioButtons: (infoarea) ->
        # remove the function that binds toggle switches to our button
        $(infoarea).find('input').unbind('change', infoarea.boundRadioFunction)
        # remove the function that binds our button to the toggle switches
        if infoarea.boundChangeToggle
            elm = infoarea.boundChangeToggle[0]
            func = infoarea.boundChangeToggle[1]
            index = elm.setStateCallbacks.indexOf(func)
            if index >= 0
                elm.setStateCallbacks.splice(index, 1)

    @prereqsToString: (prereq) ->
        if not prereq?
            return ""
        if prereq.subject
            return Course.hashCourse(prereq)
        if prereq.op
            # only give a pretty result if our data is formatted correctly
            if typeof prereq.op is 'string'
                return "(" + (Course.prereqsToString(p) for p in prereq.data).join(" #{prereq.op} ") + ")"
            else
                return ""
        return

    @prereqsToDivs: (prereq) ->
        # create a string representing the dom structure
        prereqsToDivs = (prereq) ->
            if not prereq?
                return ""
            if prereq.subject
                hash = Course.hashCourse(prereq)
                return "<course id='#{hash}' subject='#{prereq.subject}' number='#{prereq.number}'>#{hash}</course>"
            if prereq.op
                # only give a pretty result if our data is formatted correctly
                if typeof prereq.op is 'string'
                    return "<ul class='prereq-tree prereq-#{prereq.op}'><li class='prereq-tree prereq-#{prereq.op}'>" + (prereqsToDivs(p) for p in prereq.data).join("</li><li class='prereq-tree prereq-#{prereq.op}'>") + "</ul>"
                else
                    return ""
            return
        # once we have everything as a dom element, replace all the courses with course
        # buttons that are clickable
        divs = $(prereqsToDivs(prereq))
        for elm in divs.find('course')
            subject = elm.getAttribute('subject')
            number = elm.getAttribute('number')
            course = new CourseShell({subject: subject, number: number})
            courseElm = course.getButton()
            elm.parentNode.replaceChild(courseElm, elm)
        return divs

    # returns the prereq pruned so that any branches whose
    # requirements are met are no longer there
    # courses should be a list of course hashes
    @prunePrereqs: (prereq, courses) ->
        if not prereq?
            throw new Error("Yikes.  We errored while pruning the prereqs!")

        ret = {op: 'and', data: []}
        if prereq.subject
            if courses.indexOf(Course.hashCourse(prereq)) is -1
                ret.data.push prereq
        switch prereq.op
            when 'or'
                ret.op = 'or'
                for course in prereq.data
                    # if we're in an 'or' list and we've found one of our items,
                    # we're done!  Return an empty list
                    prunedBranch = Course.prunePrereqs(course, courses)
                    if prunedBranch.data?.length == 0
                        return {op: 'and', data: []}
                    # if our branch isn't empty, we better keep it around
                    ret.data.push prunedBranch
            when 'and'
                for course in prereq.data
                    # if we're in an 'and' list, we need to keep any branches
                    # that have not been fully met
                    prunedBranch = Course.prunePrereqs(course, courses)
                    if prunedBranch.data?.length != 0
                        # if our branch isn't empty, we better keep it around
                        ret.data.push prunedBranch
        return ret

    # Takes prereq object and simplifies it by remove unnecessary 'parens'
    # eg. (MATH100) and (MATH101) -> MATH100 and MATH101
    @simplifyPrereqs: (prereq) ->
        removeParen = (prereq) ->
            if not prereq.data?
                return prereq
            if prereq.data.length == 1
                return removeParen(prereq.data[0])
            return {op: prereq.op, data: (removeParen(p) for p in prereq.data)}
        return removeParen(prereq)

    # returns a flat list of all prereqs.
    @flattenPrereqs: (prereq) ->
        if prereq?.subject
            return [prereq]
        if prereq?.op
            ret = []
            for c in prereq.data
                ret = ret.concat(Course.flattenPrereqs(c))
            return ret
        return []
        throw new Error('Error flattening prereqs')

###
# CourseShell looks like a Course button, but it is empty inside.
# Instead, by setting just the subject and number, CourseShell can
# be used to add a button that will dynamically load a courses information
# when clicked
###
class CourseShell extends Course


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

    # returns a string representing the graph in
    # graphviz dot format
    toDot: (name, titles={}) ->
        ret = "digraph #{name} {\n"
        ret += "\tnode [shape=box,style=rounded]\n"
        for e in @edges
            ret += "\t\"#{e[0]}\" -> \"#{e[1]}\"\n"
        ret += "\n"
        for i in [1, 2, 3, 4]
            if @years
                ret += "\tsubgraph year#{i} {\n"
                ret += "\t\trank=same\n"
                ret += "\t\tlabel=\"Year #{i}\"\n"
                for c in @years[i]
                    ret += "\t\t\t\"#{c.hash}\" [label=<<font color=\"red\">#{c.hash}</font><br/><font color=\"blue\">#{titles[c]}</font>>]\n"
                ret += "\n\t}\n"
        ret += "}"

        return ret
    ###
    # Functions for doing rankings and orderings of graphs
    # to implement the dot graph layout algorithm
    ###

    # generates a ranking such that no neighbors ranks are equal
    # and children always have a higher rank than parents
    generateFeasibleRank: (graph=this) ->
        graph._generateForwardNeighborHash()
        graph._generateBackwardNeighborHash()
        ranks = {}
        for n of @nodes
            # figure out the maximum and minimum ranks of our parents
            # and our children, so we can choose a rank between them
            min_rank = 0
            max_rank = 1
            for parent in (graph.backwardNeighborHash[n] || [])
                if ranks[parent]
                    min_rank = Math.max(ranks[parent], min_rank)
            for child in (graph.forwardNeighborHash[n] || [])
                if ranks[child]
                    max_rank = Math.min(ranks[child], max_rank)
            ranks[n] = (min_rank + max_rank) / 2
        # our ranks are floating point numbers at the moment.
        # We need to order them and make them all integers for the
        # next part of the dot algorithm
        rankFracs = (v for k,v of ranks)
        rankFracs.sort()
        rankFracHash = {}
        for d,i in rankFracs
            rankFracHash[d] = i
        for k,v of ranks
            ranks[k] = rankFracHash[v]
        return ranks
    # given the ranks, returns the vertices of a tree
    # containing rootNode that is maximal and has the property
    # that the difference between the ranks of neighboring
    # nodes is equal to that edge's minRankDelta.
    #
    # This function assumes the graph is directed with only one source.  If
    # rootNode is set, it is assumed rootNode is a source
    findMaximalTightTree: (ranks, rootNode, graph=this) ->
        DEFAULT_DELTA = 1
        minRankDelta = graph.minRankDelta || {}

        expandTightTree = (tailNode, headNode, treeNodes={}, edges=[]) ->
            # if where we're looking has already been included in the tree,
            # we shouldn't try to grow the tree in that direction, lest we add a
            # cycle
            if treeNodes[headNode]
                return treeNodes

            edgeDelta = minRankDelta[[tailNode, headNode]] || DEFAULT_DELTA
            # if we are a tight edge, or if we are the base case where we start with headNode==tailNode,
            # proceed to add branches to the tree
            if ranks[headNode] - ranks[tailNode] == edgeDelta or headNode == tailNode
                treeNodes[headNode] = true
                edges.push [tailNode, headNode] if tailNode != headNode
                for c in (graph.forwardNeighborHash[headNode] || [])
                    expandTightTree(headNode, c, treeNodes, edges)
            return {nodes: treeNodes, edges: edges}

        if not rootNode
            sources = graph.findSources()
            if sources.length == 0
                throw new Error("Tried to find a Maximal and Tight tree on a graph with no sources!")
        else
            sources = [rootNode]

        maximalTree = expandTightTree(sources[0], sources[0])
        return maximalTree

    ###
    # returns the minimum difference in ranks between
    # node and its ancestors.
    getRankDiff: (ranks, node, graph=this) ->
        graph._generateBackwardNeighborHash()
        ancestors = graph.backwardNeighborHash[node] || []
        diff = Infinity
        for n in ancestors
            diff = Math.min(diff, ranks[node] - ranks[n])
        return diff

    # returns the minimum difference in ranks among node
    # and its ancestors minus the minimum allowed rank delta
    getSlack: (ranks, node, graph=this) ->
        DEFAULT_DELTA = 1
        minRankDelta = graph.minRankDelta || {}

        graph._generateBackwardNeighborHash()
        ancestors = graph.backwardNeighborHash[node] || []
        diff = Infinity
        tail = null
        for n in ancestors
            rankDiff = ranks[node] - ranks[n] - (minRankDelta[[n,node]] || 0)
            if rankDiff < diff
                diff = rankDiff
                tail = n
        return {slack: diff, edge: [tail, node]}
    ###

    # returns an edge with one node in tree and one node not in tree
    # with the slack minimum
    getIncidentEdgeOfMinimumSlack: (ranks, tree, graph=this) ->
        DEFAULT_DELTA = 1
        minRankDelta = graph.minRankDelta || {}

        incidentEdges = (e for e in graph.edges when (tree[e[0]] ^ tree[e[1]])) # ^ is xor
        giveSlack = (edge) ->
            rankDiff = Math.abs(ranks[edge[0]] - ranks[edge[1]])
            return rankDiff - (minRankDelta[edge] || 0)

        slacks = ([giveSlack(e),e] for e in incidentEdges)
        slacks.sort()
        return slacks[0]

    # produces a set of ranks and a feasible spanning tree
    # derived from those ranks for use in the dot algorithm
    findFeasibleSpanningTree: (graph=this) ->
        # generate a valid ranking for all the nodes.
        # This may not be tight, but we will tighten it.
        ranks = graph.generateFeasibleRank()

        tree = graph.findMaximalTightTree(ranks)
        numNodes = Object.keys(graph.nodes).length
        # findMaximalTightTree will return the largest feasible tree
        # possible starting at the source node.  If this tree ever includes
        # all the vertices, we're done.
        while Object.keys(tree.treeNodes).length < numNodes
            [slack, edge] = graph.getIncidentEdgeOfMinimumSlack(ranks, tree.treeNodes)




