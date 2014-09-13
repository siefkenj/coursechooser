loadSVG = (url, callback) ->
    xhr = new XMLHttpRequest
    xhr.onreadystatechange = ->
        ###
        # when running from file:// xhr.status is always 0
        #if xhr.readyState is 4 and xhr.status is 200
        ###
        if xhr.readyState is 4
            graph = document.getElementById('graphview-graph')
            graph.innerHTML = xhr.responseText
            callback?(graph.childNodes[0])
        return

    xhr.open('GET', url, true)
    xhr.setRequestHeader('Content-type', 'image/svg+xml')
    xhr.send()
    return

###
# pass in a Date object and returns {year: .., term: ..}
# object corresponding to the school year
###
computeTermFromDate = (date) ->
    ###
    # summer: 5-8
    # fall: 9-12
    # spring: 1-5   in this case we need to subtract 1 from the year, 'cause it counts as the previous year!
    ###
    year = date.getYear() + 1900
    month = date.getMonth()
    if 0 <= month <= 4
        term = 'spring'
        year -= 1
    else if 4 <= month <= 7
        term = 'summer'
    else
        term = 'fall'
    return {year: year, term: term}

makeResizableAndClickable = (svg, container=document) ->
    #svg.setAttribute('preserveAspectRatio', 'none')
    zoomer = new SVGZoomer(svg)
    zoomer.zoomFit()
    container.querySelector('#graphview-zoom-in').onclick = ->
        zoomer.zoomIn()
        return
    container.querySelector('#graphview-zoom-out').onclick = ->
        zoomer.zoomOut()
        return
    container.querySelector('#graphview-zoom-fit').onclick = ->
        zoomer.zoomFit()
        return

    manager = new GraphManager(svg, zoomer, container)
    return manager

###
# responsible for loading the graphview template and dynamically
# injecting the appropriate stylesheets, etc.
###
class GraphviewCreator
    constructor: ->
        @loadError = false
        @templateText = ''
        ###
        # the make file dynamically injects NAV_TEMPLATE into graphview.coffee, but we should
        # be able to use it without compiling
        ###
        if typeof NAV_TEMPLATE isnt 'undefined'
            @templateText = NAV_TEMPLATE
        @loadTemplate('graphview.html')

    loadTemplate: (url, callback=(->)) ->
        if @loadError
            return
        ###
        # if things are already loaded, don't try to reload
        ###
        if @templateText
            (callback.bind(@))()
            return

        xhr = new XMLHttpRequest
        xhr.onreadystatechange = =>
            ###
            # when running from file:// xhr.status is always 0
            #if xhr.readyState is 4 and xhr.status is 200
            ###
            if xhr.readyState is 4
                if not xhr.responseText
                    @loadError = true
                @templateText = xhr.responseText
                ###
                # call our callback, but to avoid hassle, make sure
                # we call it with the appropriate _this_ context.
                ###
                (callback.bind(@))()
        xhr.open('GET', url, true)
        xhr.setRequestHeader('Content-type', 'image/svg+xml')
        xhr.send()
        return
    injectHeader: ->
        if @loadError
            return
        if not @templateText
            @loadTemplate('graphview.html', @injectHeader)
            return

        frag = document.createElement('div')
        frag.innerHTML = @templateText
        for elm in frag.querySelectorAll('link[rel=stylesheet]')
            document.body.appendChild(elm)
        for elm in frag.querySelectorAll('style')
            document.body.appendChild(elm)
        ###
        # clean up, just in case
        ###
        frag.innerHTML = ''
        return
    createGraphviewInstance: (svgUrl, imgElm) ->
        if @loadError
            return
        if not @templateText
            @loadTemplate('graphview.html', @createGraphviewInstance)
            return

        frag = document.createElement('div')
        frag.innerHTML = @templateText
        graphviewDiv = frag.querySelector('#graphview')

        ###
        # once the svg is loaded, link it all up and inject it
        ###
        onSvgLoadComplete = (svgText) =>
            if not svgText or not imgElm.parentNode
                return
            ###
            # if we successfully have SVG text, we'll replace the image
            ###
            imgElm.parentNode.replaceChild(graphviewDiv, imgElm)

            parent = graphviewDiv.querySelector('#graphview-graph')
            parent.innerHTML = svgText
            makeResizableAndClickable(parent.querySelector('svg'), graphviewDiv)
            return

        ###
        # start the load request
        ###
        xhr = new XMLHttpRequest
        xhr.onreadystatechange = =>
            ###
            # when running from file:// xhr.status is always 0
            #if xhr.readyState is 4 and xhr.status is 200
            ###
            if xhr.readyState is 4
                onSvgLoadComplete(xhr.responseText)
            return
        xhr.open('GET', svgUrl, true)
        xhr.setRequestHeader('Content-type', 'image/svg+xml')
        xhr.send()

        ###
        # graphviewDiv will be dynamically updated when the svg has loaded
        ###
        return graphviewDiv
    ###
    # pass in an <img> element and replaceImage will find the src url,
    # replace the extension with .svg and attempt to make an interactive
    # graph that replaces the imgElm
    ###
    replaceImage: (imgElm) ->
        afterTemplateLoads = =>
            url = imgElm.getAttribute('src')
            ###
            # replace the extension
            ###
            url = url.replace(/\.\w*$/, '.svg')
            
            ###
            # let's try and replace ourselves with our ajax loaded svg
            ###
            @createGraphviewInstance(url, imgElm)
            return

        @loadTemplate('graphview.html', afterTemplateLoads)
        return


###
# Mini matrix library
###
Mat =
    row: (n) ->
        ret = new Array(n)
        for i in [0...n]
            ret[i] = 0
        return ret
    zeros: (rows,cols) ->
        ret = new Array(rows)
        for i in [0...rows]
            ret[i] = Mat.row(cols)
        return ret
    identity: (rows, cols) ->
        ret = Mat.zeros(rows, cols)
        for i in [0...Math.min(rows, cols)]
            ret[i][i] = 1
        return ret
    copy: (mat) ->
        rows = mat.length
        cols = mat[0].length
        ret = new Array(rows)
        for i in [0...rows]
            ret[i] = mat[i].slice()
        return ret
    transpose: (mat) ->
        rows = mat.length
        cols = mat[0].length
        ret = Mat.zeros(cols, rows)
        for i in [0...cols]
            for j in [0...rows]
                ret[i][j] = mat[j][i]
        return ret
    ###
    # in-place greather-than
    ###
    gt: (mat, num) ->
        rows = mat.length
        cols = mat[0].length
        for i in [0...rows]
            for j in [0...cols]
                mat[i][j] = (mat[i][j] > num) | 0
        return mat
    ###
    # in-place sum
    ###
    sum: (mat1, mat2) ->
        rows = mat1.length
        cols = mat1[0].length
        ret = mat1
        for i in [0...rows]
            for j in [0...cols]
                ret[i][j] = mat1[i][j] + mat2[i][j]
        return ret

    ###
    # dot product of two vectors
    ###
    dot: (vec1, vec2) ->
        ret = 0
        for i in [0...vec1.length]
            ret += vec1[i]*vec2[i]
        return ret
    ###
    # multiply two matrices
    ###
    mul: (mat1, mat2) ->
        mat2t = Mat.transpose(mat2)
        rows = mat1.length
        cols = mat2[0].length
        ret = Mat.zeros(rows, cols)
        for i in [0...rows]
            for j in [0...cols]
                ret[i][j] = Mat.dot(mat1[i], mat2t[j])
        return ret
    ###
    # raise a matrix to a power
    ###
    pow: (mat, pow) ->
        ###
        # to be efficient, we compute successive squares
        # and then multiply those together to get the end result
        ###
        bin = Mat.numToBinary(pow)
        powers = new Array(bin.length)
        curr = mat
        for i in [0...bin.length]
            powers[i] = curr
            curr = Mat.mul(curr, curr)
        ret = Mat.identity(mat.length, mat[0].length)
        for a,i in bin when a
            ret = Mat.mul(ret, powers[i])
        return ret
    ###
    # returns a matrix that is a sum of at least
    # one of ever power of mat up to power at least pow.
    # e.g. powerSum(A, 3) = I + aA + bA^2 +cA^3
    ###
    powerSum: (mat, pow) ->
        bin = Mat.numToBinary(pow)
        curr = mat
        for i in [0...bin.length]
            curr = Mat.sum(Mat.mul(curr, mat), mat)
        return curr

    numToBinary: (num) ->
        if num <= 0
            len = 0
        else
            len = Math.floor(Math.log(num)/Math.log(2)) + 1
        ret = new Array(len)
        curr = num
        for i in [0...len]
            ret[i] = curr & 1
            curr = curr >> 1
        return ret
    prettyPrint: (mat) ->
        padd3 = (num) ->
            return ("   "+num).slice(-3)
        rowToStr = (row) ->
            return (padd3(e) for e in row).join('')
        return (rowToStr(row) for row in mat).join('\n')

class SVGZoomer
    ZOOM_FACTOR: 1.2
    PAN_TOLERANCE: 5
    constructor: (@svg) ->
        @parent = @svg.parentNode

        ###
        # compatibility stuff
        ###
        try
            ###
            # see if we can successfully execute the builtin getElementById by trying to locate a bogus element
            ###
            @svg.querySelector('boguselement')
        catch e
            @svg.querySelector = (str) => @parent.querySelector(str)
            @svg.querySelectorAll = (str) => @parent.querySelectorAll(str)

        ###
        # get the dimensions
        ###
        if @svg.getAttribute('viewBox')
            dims = @svg.getAttribute('viewBox').split(/[^\w]+/)
            dims = (parseFloat(d) for d in dims)
            @width = dims[2]-dims[0]
            @height = dims[3] - dims[1]
        else
            @width = parseFloat(@svg.getAttribute('width'))
            @height = parseFloat(@svg.getAttribute('height'))
            @svg.setAttribute('viewBox', "0 0 #{@width} #{@height}")
        @currentZoomFactor = 1
        @aspect = @width/@height
        ### keep track of whether our last call was zoomFit or not. ###
        @lastZoomAction = null
        @zoom()

        ###
        # panning state
        ###
        @buttonPressed = false
        @oldMousePos = [-1, -1]
        @panning = false
        @totalPan = [0, 0]
        @svg.addEventListener('mousedown', @_onMouseDown, false)
        document.body.addEventListener('mouseup', @_onMouseUp, false)
        @svg.addEventListener('mousemove', @_onMouseMove, false)
        return
    _onMouseUp: (event) =>
        @buttonPressed = false
        ### reset the pan state ###
        @totalPan[0] = 0
        @totalPan[1] = 1
        @panning = false
        return
    _onMouseDown: (event) =>
        if event.button is 0
            @buttonPressed = true
        return
    _onMouseMove: (event) =>
        x = event.clientX
        y = event.clientY
        if @oldMousePos[0] is -1
            @oldMousePos[0] = x
            @oldMousePos[1] = y
        dx = x - @oldMousePos[0]
        dy = y - @oldMousePos[1]
        if not @buttonPressed or (dx is 0 and dy is 0)
            @oldMousePos[0] = x
            @oldMousePos[1] = y
            return

        @totalPan[0] += dx
        @totalPan[1] += dy
        ###
        # the first time we have moved more than @PAN_TOLERANCE, we should pan by the amount accumulated
        ###
        if (not @panning) and Math.abs(@totalPan[0]) + Math.abs(@totalPan[1]) > @PAN_TOLERANCE
            @panning = true
            dx = @totalPan[0]
            dy = @totalPan[1]

        if @panning
            @parent.scrollTop -= dy
            @parent.scrollLeft -= dx

        @oldMousePos[0] = x
        @oldMousePos[1] = y
        return

    zoomIn: (factor=@ZOOM_FACTOR) ->
        @lastZoomAction = 'in'
        @currentZoomFactor *= factor
        @zoom()
        return
    zoomOut: (factor=@ZOOM_FACTOR) ->
        @lastZoomAction = 'out'
        @currentZoomFactor /= factor
        @zoom()
        return
    zoomFit: () ->
        @lastZoomAction = 'fit'
        {width, height} = @parent.getBoundingClientRect()
        @currentZoomFactor = width/@width
        @zoom()
        return
    zoom: (factor=@currentZoomFactor) ->
        width = Math.round(@width*factor)
        height = Math.round(@height*factor)
        @zoomedWidth = width
        @zoomedHeight = height
        @svg.setAttribute('width', width)
        @svg.setAttribute('height', height)
        ###
        # webkit hack: For some reason svg attribute values for width don't work when theyre smaller than viewbox width
        ###
        @svg.setAttribute('style', "width: #{width}; height: #{height};")
        return

class GraphManager
    hashCourse = (course) ->
        if typeof course is 'string'
            return course
        return "#{course.subject} #{course.number}"
    sanitizeId = (str) ->
        return (''+str).replace(/\W+/g,'-')
    addClass = (elm, cls) ->
        oldCls = elm.getAttribute('class') || ''
        if oldCls.split(/\s+/).indexOf(cls) >= 0
            return
        elm.setAttribute('class', oldCls + ' ' + cls)
        return
    removeClass = (elm, cls) ->
        oldCls = elm.getAttribute('class') || ''
        if not oldCls.match(cls)
            return
        newCls = (c for c in oldCls.split(/\s+/) when c isnt cls)
        elm.setAttribute('class', newCls.join(' '))
        return

    constructor: (@svg, @zoomer, @container=document) ->
        ###
        # compatibility stuff
        ###
        try
            ###
            # see if we can successfully execute the builtin querySelector by trying to locate a bogus element
            # It is not enought to check @svg.querySelector == null, since it is defined in Firefox 10, but throws an error
            ###
            @svg.querySelector('boguselement')
        catch e
            @svg.querySelector = (str) => @parent.querySelector(str)
            @svg.querySelectorAll = (str) => @parent.querySelectorAll(str)

        @parent = @svg.parentNode
        @divCourseinfo = @container.querySelector('#graphview-courseinfo')
        @divGraph = @container.querySelector('#graphview-graph')
        @divNav = @container.querySelector('#graphview-nav')
        @currentlySelected = null
        @currentlySelectedTerms = {fall: true, spring: true, summer: true}

        ###
        # remove any styles that have been inserted, we will use stylesheets instead
        ###
        for elm in @svg.querySelectorAll('*')
            elm.removeAttribute('style')
        @data = JSON.parse(decodeURIComponent(@svg.querySelector('coursemapper').textContent))
        @processData()

        ###
        # ensure nodes are clickable and set their title appropriately
        ###
        for elm in @svg.querySelectorAll('g.node')
            elm.addEventListener('click', @_onCourseClicked, true)
            info = @courses[elm.courseHash]
            if info
                try
                    desc = "#{info.subject} #{info.number}: #{info.data.title}"
                    elm.setAttribute('title', desc)
                catch e
                    ''
        # make all the coop links work
        for coop in @data.coops || []
            try
                elm = @svg.getElementById(coop.id)
                elm._coopLink = coop.url
                elm.setAttribute('title', coop.label)
                if elm._coopLink
                    elm.onclick = (event) ->
                        window.open(event.currentTarget._coopLink)
                        return
            catch e
                ''

        ###
        # closable infoarea
        ###
        closeInfoArea = =>
            @setCourseinfoVisibility(false)
            ###
            # if you zoom-fit while the infoarea was open and you
            # close it, you expect the graph to fit to the newly-enlarged area
            ###
            if @zoomer?.lastZoomAction is 'fit'
                @zoomer.zoomFit()
            return

        @divCourseinfo.querySelector('.graphview-close-button').addEventListener('click', closeInfoArea, true)

        ###
        # set up the term selection menu
        ###
        @divNav.querySelector('#graphview-term-menu-fall').addEventListener('click', @_createTermToggler('fall'), true)
        @divNav.querySelector('#graphview-term-menu-spring').addEventListener('click', @_createTermToggler('spring'), true)
        @divNav.querySelector('#graphview-term-menu-summer').addEventListener('click', @_createTermToggler('summer'), true)

        #@svg.addEventListener('click', @_onClick, false)
    ###
    # Get a list of all the nodes and their corresponding
    # dom elements and tag each dom element with an expando
    # property linking back to its name
    ###
    processData: ->
        @courses = {}
        @coursesList = []
        for node,i in @data.nodes
            course = node.course
            hash = hashCourse(course)
            @courses[hash] = course
            @coursesList.push hash
            course.listPos = i
            course.year = node.year
            ###
            # mark each clickable node with a reference to its unmangled hash so we
            # can get back to it.
            ###
            elm = @svg.querySelector("##{sanitizeId(hash)}")
            if elm
                course.elm = elm
                elm.courseHash = hash
        ###
        # make sure any electives that aren't explicitly
        # specified have a reference to their info for use on click
        ###
        for cluster in @data.clusters when cluster.courses?.length is 0
            course = cluster.cluster
            course.isElectivesNode = true
            hash = hashCourse(course)
            @courses[hash] = course
            elm = @svg.querySelector("##{sanitizeId(hash)}")
            if elm
                course.elm = elm
                elm.courseHash = hash

        ###
        # compute adjacency matrices
        ###
        numNodes = @coursesList.length
        @adjacencyMat = Mat.zeros(numNodes, numNodes)
        for edge in @data.edges
            if edge.properties.style?.match(/invis/)
                continue
            i = @courses[edge.edge[0]].listPos
            j = @courses[edge.edge[1]].listPos
            @adjacencyMat[i][j] = 1
            if edge.properties.coreq
                @adjacencyMat[i][j] = 2
        ###
        # compute coreq adjacencies
        ###
        @adjacencyMatCoreq = Mat.gt(Mat.copy(@adjacencyMat), 1)
        @adjacencyMatCoreq = Mat.sum(@adjacencyMatCoreq, Mat.transpose(@adjacencyMatCoreq))

        @adjacencyMat = Mat.sum(@adjacencyMat, @adjacencyMatCoreq)
        @span = Mat.gt(Mat.powerSum(@adjacencyMat, @adjacencyMat.length), 0)
        @correqSpan = Mat.gt(Mat.powerSum(@adjacencyMatCoreq, @adjacencyMatCoreq.length), 0)
        return
    ###
    # returns a list of all the prereqs/coreqs for a course
    ###
    coursePrereqs: (course, excludeCorreqs=false) ->
        hash = hashCourse(course)
        ###
        # if we're not a standard course (e.g. an electives node), we wont have a listPos.
        # Bail in this case.
        ###
        if not @courses[hash].listPos?
            return []
        spanT = Mat.transpose(@span)
        ### this doesn't need to be transposed because the coreq matrix is symmetric ###
        adjT = @adjacencyMatCoreq
        index = @courses[hash].listPos
        ret = []
        ###
        # we can get into funny situations where we appear in our own span.  We should never appear
        # in our own prereq list.
        ###
        for e,i in spanT[index] when (e and not (hash is @coursesList[i]))
            ###
            # if we're in the span 'cause we're a coreq, move along
            ###
            if excludeCorreqs and adjT[index][i]
                continue
            ret.push @coursesList[i]
        return ret
    ###
    # returns a list of all the prereqs/coreqs for a course
    ###
    courseCoreqs: (course) ->
        hash = hashCourse(course)
        ###
        # if we're not a standard course (e.g. an electives node), we wont have a listPos.
        # Bail in this case.
        ###
        if not @courses[hash].listPos?
            return []
        ### this doesn't need to be transposed because the coreq matrix is symmetric ###
        adjT = @adjacencyMatCoreq
        index = @courses[hash].listPos
        ret = []
        ###
        # we can get into funny situations where we appear in our own span.  We should never appear
        # in our own prereq list.
        ###
        for e,i in adjT[index] when (e and not (hash is @coursesList[i]))
            ret.push @coursesList[i]
        return ret
    ###
    # returns a callback to be executed whenever
    # the visibility checkbox for that term is checked
    # term is in ['fall','spring','summer','any']
    ###
    _createTermToggler: (term) ->
        callback = =>
            switch term
                when 'fall'
                    @currentlySelectedTerms['fall'] = not @currentlySelectedTerms['fall']
                when 'spring'
                    @currentlySelectedTerms['spring'] = not @currentlySelectedTerms['spring']
                when 'summer'
                    @currentlySelectedTerms['summer'] = not @currentlySelectedTerms['summer']
            ###
            # set the proper icons on the menu
            ###
            for t in ['fall', 'spring', 'summer']
                if @currentlySelectedTerms[t]
                    @divNav.querySelector("#graphview-term-menu-#{t} i").setAttribute('class', 'icon-check')
                else
                    @divNav.querySelector("#graphview-term-menu-#{t} i").setAttribute('class', 'icon-check-empty')
            @filterClassesByTerm(@currentlySelectedTerms)
            return
        return callback



    _onClick: (event) =>
        if event.target.getAttribute('class')?.match(/course/) or true
            event.currentTarget = event.target
            @_onCourseClicked(event)
        return
    _onCourseClicked: (event) =>
        elm = event.currentTarget
        if @currentlySelected is elm.courseHash
            @deselectAll()
        else
            @selectCourse(elm.courseHash)
        return
    ###
    # select a course and highlight all its prereqs
    ###
    selectCourse: (course) ->
        hash = hashCourse(course)
        prereqs = @coursePrereqs(hash)
        ###
        # highlight all the course nodes
        ###
        for _,c of @courses
            removeClass(c.elm, 'highlight')
            removeClass(c.elm, 'highlight2')
        for prereq in prereqs
            addClass(@courses[prereq].elm, 'highlight')
        addClass(@courses[hash].elm, 'highlight')
        ###
        # highlight all the prereq arrows
        ###
        for elm in @svg.querySelectorAll('g.edge')
            removeClass(elm, 'highlight')
        for prereq in prereqs.concat([hash])
            id = sanitizeId(prereq)
            for elm in @svg.querySelectorAll("[target=#{id}]")
                addClass(elm, 'highlight')
        @createCourseSummary(course)
        @currentlySelected = course
        @setCourseinfoVisibility(true)
        return

    deselectAll: ->
        for _,c of @courses
            removeClass(c.elm, 'highlight')
            removeClass(c.elm, 'highlight2')
        for elm in @svg.querySelectorAll('g.edge')
            removeClass(elm, 'highlight')
        @currentlySelected = null
        @setCourseinfoVisibility(false)
        return

    courseRequirementsSummary: (course) ->
        hash = hashCourse(course)
        prereqs = @coursePrereqs(hash, true)
        years = {1:[], 2:[], 3:[], 4:[]}
        for prereq in prereqs
            c = @courses[prereq]
            years[c.year] = years[c.year] || []
            years[c.year].push c
        coreqs = @courseCoreqs(hash)
        years['coreq'] = []
        for coreq in coreqs
            c = @courses[coreq]
            years['coreq'].push c

        return years
    createCourseSummary: (course) ->
        hash = hashCourse(course)
        course = @courses[course]
        infoArea = @container.querySelector('#graphview-courseinfo')

        ###
        # we have a special display if we're an electives node
        ###
        if course.isElectivesNode
            addClass(infoArea.querySelector('#graphview-courseinfo-text'), 'invisible')
            infoArea = infoArea.querySelector('#graphview-electivesinfo-text')
            removeClass(infoArea, 'invisible')
            infoArea.querySelector('.name')?.textContent = course.title

            link = course.data?.url || '#'
            calendarLink = infoArea.querySelector('#graphview-electivesinfo-link')
            if calendarLink
                calendarLink.setAttribute('href', link)
            if course.data?.url
                removeClass(infoArea.querySelector('.moreinfo'), 'invisible')
                infoLink = infoArea.querySelector('.moreinfo a')
                infoLink.setAttribute('href', link)
                infoLink.textContent = link
            else
                addClass(infoArea.querySelector('.moreinfo'), 'invisible')


            requirement = "#{course.requirements?.units} #{course.requirements?.unitLabel}"
            infoArea.querySelector('.title')?.textContent = requirement

            if course.data?.description
                ###
                # let's do some pretty formatting of the description so it looks
                # more like how it was typed
                ###
                emailRegexp = /([\w\-\.]+@[\w\-\.]+)/gi
                urlRegex = /((http:|https:)\/\/[\w\-\.~%?\/\#]+)/gi

                formatted = course.data.description.replace(/\n(\s|\n)*\n/g,'<br/><br/>')
                formatted = formatted.replace(urlRegex, "<a href='$1'>$1</a>")
                formatted = formatted.replace(emailRegexp, "<a href='mailto::$1'>$1</a>")
                infoArea.querySelector('.description')?.innerHTML = formatted
            else
                infoArea.querySelector('.description')?.textContent = "Take #{requirement}."

            return

        addClass(infoArea.querySelector('#graphview-electivesinfo-text'), 'invisible')
        infoArea = infoArea.querySelector('#graphview-courseinfo-text')
        removeClass(infoArea, 'invisible')


        infoArea.querySelector('.name')?.textContent = hash
        infoArea.querySelector('.title')?.textContent = course.data?.title

        ###
        # prepare the appropriate calendar link
        ###
        academicTerm = computeTermFromDate(new Date)
        link = "http://web.uvic.ca/calendar#{academicTerm.year}/CDs/#{course.subject}/#{course.number}.html"
        calendarLink = infoArea.querySelector('#graphview-calendar-link')
        if calendarLink
            calendarLink.setAttribute('href', link)

        for term in ['fall', 'spring', 'summer']
            elm = infoArea.querySelector(".#{term}")
            if course.data?.terms_offered[term]
                removeClass(elm, "hidden")
            else
                addClass(elm, "hidden")
        infoArea.querySelector('.description')?.textContent = course.data?.description

        ###
        # construct the prereq list
        ###
        years = @courseRequirementsSummary(course)
        numPrereqs = years[1].length + years[2].length + years[3].length + years[4].length
        if numPrereqs > 0
            removeClass(infoArea.querySelector('.prereq'), "invisible")
            for year in [1,2,3,4]
                parent = infoArea.querySelector(".year#{year}")
                elm = parent.querySelector('ul')
                list = []
                prereqs = years[year]
                for c in prereqs
                    list.push "<li title='#{c.subject} #{c.number}: #{c.data.title}' course='#{hashCourse(c)}'>#{hashCourse(c)}</li>"
                list.sort()
                elm?.innerHTML = list.join('')
                if list.length is 0
                    addClass(parent, "invisible")
                else
                    removeClass(parent, "invisible")
                ###
                # make the pre-reqs highlight on hover and make the clickable
                ###
                for li in elm?.querySelectorAll('li') || []
                    li.onmouseover = @_onPrereqHoverEnter
                    li.onmouseout = @_onPrereqHoverLeave
                    li.onclick = (event) =>
                        elm = event.currentTarget
                        course = elm.getAttribute('course')
                        @selectCourse(course)
                        return
        else
            addClass(infoArea.querySelector('.prereq'), "invisible")
        ###
        # construct the prereq list
        ###
        parent = infoArea.querySelector(".coreq")
        elm = parent.querySelector('ul')
        list = []
        prereqs = years['coreq']
        for c in prereqs
            list.push "<li title='#{c.subject} #{c.number}: #{c.data.title}'>#{hashCourse(c)}</li>"
        list.sort()
        elm?.innerHTML = list.join('')
        ###
        # make the co-reqs highlight on hover and make the clickable
        ###
        for li in elm?.querySelectorAll('li') || []
            li.onmouseover = @_onPrereqHoverEnter
            li.onmouseout = @_onPrereqHoverLeave
            li.onclick = (event) =>
                elm = event.currentTarget
                course = elm.getAttribute('course')
                @selectCourse(course)
                return
        if list.length is 0
            addClass(parent, "invisible")
        else
            removeClass(parent, "invisible")
        return
    _onPrereqHoverEnter: (event) =>
        elm = event.currentTarget
        courseHash = elm.getAttribute('course')
        course = @courses[courseHash]
        if course
            addClass(course.elm, 'highlight2')
        return

    _onPrereqHoverLeave: (event) =>
        elm = event.currentTarget
        courseHash = elm.getAttribute('course')
        course = @courses[courseHash]
        if course
            removeClass(course.elm, 'highlight2')
        return
    ###
    # sets whether the courseinfo area is visible or not.
    # This function handles resizing of the graph area, etc.
    ###
    setCourseinfoVisibility: (visible=true) ->
        if visible
            removeClass(@divCourseinfo, 'invisible')
            addClass(@divGraph, 'sidepanel-visible')
        else
            addClass(@divCourseinfo, 'invisible')
            removeClass(@divGraph, 'sidepanel-visible')
        return
    ###
    # pass in an object with the terms you want to be visible.
    # Courses only offered in other terms will be transparent
    ###
    filterClassesByTerm: (terms={summer: true, fall: true, spring: true}) ->
        isOfferedInTerms = (course) ->
            for term,v of terms when v
                if course.data.terms_offered?[term]
                    return true
            return false

        for elm in @svg.querySelectorAll('.node')
            course = @courses[elm.courseHash]
            if isOfferedInTerms(course) or course.isElectivesNode
                removeClass(elm, 'transparent')
            else
                addClass(elm, 'transparent')
        return

###
# set it up so that images with the graphview attribute
# are dynamically replaced with interactive maps
###
onLoad = ->
    ###
    # only attempt to make the picture fancy if the browser has support for SVG images in the first place
    ###
    if window.SVGElement?
        creator = new GraphviewCreator
        creator.injectHeader()
        for elm in document.querySelectorAll('[graphview=true]')
            creator.replaceImage(elm)

window.addEventListener('load', onLoad, true)
