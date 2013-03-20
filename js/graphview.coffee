loadSVG = (url, callback) ->
    window.xhr = new XMLHttpRequest
    xhr.onreadystatechange = ->
        # when running from file:// xhr.status is always 0
        #if xhr.readyState is 4 and xhr.status is 200
        if xhr.readyState is 4
            graph = document.getElementById('graphview-graph')
            graph.innerHTML = xhr.responseText
            callback?(graph.childNodes[0])

    xhr.open('GET', url, true)
    xhr.setRequestHeader('Content-type', 'image/svg+xml')
    xhr.send()

resize = (svg) ->
    #svg.setAttribute('preserveAspectRatio', 'none')
    window.zoomer = new SVGZoomer(svg)
    zoomer.zoomFit()
    document.getElementById('graphview-zoom-in').onclick = ->
        zoomer.zoomIn()
    document.getElementById('graphview-zoom-out').onclick = ->
        zoomer.zoomOut()
    document.getElementById('graphview-zoom-fit').onclick = ->
        zoomer.zoomFit()

    window.manager = new GraphManager(svg)
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
    # in-place greather-than
    gt: (mat, num) ->
        rows = mat.length
        cols = mat[0].length
        for i in [0...rows]
            for j in [0...cols]
                mat[i][j] = (mat[i][j] > num) | 0
        return mat
    # in-place sum
    sum: (mat1, mat2) ->
        rows = mat1.length
        cols = mat1[0].length
        ret = mat1
        for i in [0...rows]
            for j in [0...cols]
                ret[i][j] = mat1[i][j] + mat2[i][j]
        return ret

    # dot product of two vectors
    dot: (vec1, vec2) ->
        ret = 0
        for i in [0...vec1.length]
            ret += vec1[i]*vec2[i]
        return ret
    # multiply two matrices
    mul: (mat1, mat2) ->
        mat2t = Mat.transpose(mat2)
        rows = mat1.length
        cols = mat2[0].length
        ret = Mat.zeros(rows, cols)
        for i in [0...rows]
            for j in [0...cols]
                ret[i][j] = Mat.dot(mat1[i], mat2t[j])
        return ret
    # raise a matrix to a power
    pow: (mat, pow) ->
        # to be efficient, we compute successive squares
        # and then multiply those together to get the end result
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
    # returns a matrix that is a sum of at least
    # one of ever power of mat up to power at least pow.
    # e.g. powerSum(A, 3) = I + aA + bA^2 +cA^3
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

        # compatibility stuff
        @svg.getElementById = @svg.getElementById || (id) => @parent.getElementById(id)
        @svg.querySelector = @svg.querySelector || (srt) => @parent.querySelector(str)
        @svg.querySelectorAll = @svg.querySelectorAll || (srt) => @parent.querySelectorAll(str)
        
        # get the dimensions
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

        @zoom()

        # panning state
        @buttonPressed = false
        @oldMousePos = [-1, -1]
        @panning = false
        @totalPan = [0, 0]
        @svg.addEventListener('mousedown', @_onMouseDown, false)
        document.body.addEventListener('mouseup', @_onMouseUp, false)
        @svg.addEventListener('mousemove', @_onMouseMove, false)
    _onMouseUp: (event) =>
        @buttonPressed = false
        # reset the pan state
        @totalPan[0] = 0
        @totalPan[1] = 1
        @panning = false
    _onMouseDown: (event) =>
        if event.button is 0
            @buttonPressed = true
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
        # the first time we have moved more than @PAN_TOLERANCE, we should pan by the amount accumulated
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
        @currentZoomFactor *= factor
        @zoom()
    zoomOut: (factor=@ZOOM_FACTOR) ->
        @currentZoomFactor /= factor
        @zoom()
    zoomFit: () ->
        {width, height} = @parent.getBoundingClientRect()
        @currentZoomFactor = width/@width
        @zoom()
    zoom: (factor=@currentZoomFactor) ->
        width = Math.round(@width*factor)
        height = Math.round(@height*factor)
        @zoomedWidth = width
        @zoomedHeight = height
        @svg.setAttribute('width', width)
        @svg.setAttribute('height', height)
        # webkit hack: For some reason svg attribute values for width don't work when theyre smaller than viewbox width
        @svg.setAttribute('style', "width: #{width}; height: #{height};")

class GraphManager
    hashCourse = (course) ->
        if typeof course is 'string'
            return course
        return "#{course.subject} #{course.number}"
    sanitizeId = (str) ->
        return (''+str).replace(/\W+/g,'-')
    addClass = (elm, cls) ->
        oldCls = elm.getAttribute('class')
        if oldCls.split(/\s+/).indexOf(cls) >= 0
            return
        elm.setAttribute('class', oldCls + ' ' + cls)
    removeClass = (elm, cls) ->
        oldCls = elm.getAttribute('class')
        if not oldCls.match(cls)
            return
        newCls = (c for c in oldCls.split(/\s+/) when c isnt cls)
        elm.setAttribute('class', newCls.join(' '))

    constructor: (@svg) ->
        # compatibility stuff
        @svg.getElementById = @svg.getElementById || (id) => @parent.getElementById(id)
        @svg.querySelector = @svg.querySelector || (srt) => @parent.querySelector(str)
        @svg.querySelectorAll = @svg.querySelectorAll || (srt) => @parent.querySelectorAll(str)

        @parent = @svg.parentNode
        
        # remove any styles that have been inserted, we will use stylesheets instead
        for elm in @svg.querySelectorAll('*')
            elm.removeAttribute('style')
        @data = JSON.parse(decodeURIComponent(@svg.querySelector('coursemapper').textContent))
        @processData()
        console.log @data

        for elm in @svg.querySelectorAll('g.node')
            elm.addEventListener('click', @_onCourseClicked, true)

        #@svg.addEventListener('click', @_onClick, false)
    # Get a list of all the nodes and their corresponding
    # dom elements and tag each dom element with an expando
    # property linking back to its name
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
            elm = @svg.getElementById(sanitizeId(hash))
            if elm
                course.elm = elm
                elm.courseHash = hash
        # compute adjacency matrices
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
        # compute coreq adjacencies
        @adjacencyMatCoreq = Mat.gt(Mat.copy(@adjacencyMat), 1)
        @adjacencyMatCoreq = Mat.sum(@adjacencyMatCoreq, Mat.transpose(@adjacencyMatCoreq))

        @adjacencyMat = Mat.sum(@adjacencyMat, @adjacencyMatCoreq)
        @span = Mat.gt(Mat.powerSum(@adjacencyMat, @adjacencyMat.length), 0)
        @correqSpan = Mat.gt(Mat.powerSum(@adjacencyMatCoreq, @adjacencyMatCoreq.length), 0)
        return
    # returns a list of all the prereqs/coreqs for a course
    coursePrereqs: (course, excludeCorreqs=false) ->
        hash = hashCourse(course)
        spanT = Mat.transpose(@span)
        adjT = @adjacencyMatCoreq   # this doesn't need to be transposed because the coreq matrix is symmetric
        index = @courses[hash].listPos
        ret = []
        # we can get into funny situations where we appear in our own span.  We should never appear
        # in our own prereq list.
        for e,i in spanT[index] when (e and not (hash is @coursesList[i]))
            # if we're in the span 'cause we're a coreq, move along
            if excludeCorreqs and adjT[index][i]
                continue
            ret.push @coursesList[i]
        return ret
    # returns a list of all the prereqs/coreqs for a course
    courseCoreqs: (course) ->
        hash = hashCourse(course)
        adjT = @adjacencyMatCoreq   # this doesn't need to be transposed because the coreq matrix is symmetric
        index = @courses[hash].listPos
        ret = []
        # we can get into funny situations where we appear in our own span.  We should never appear
        # in our own prereq list.
        for e,i in adjT[index] when (e and not (hash is @coursesList[i]))
            ret.push @coursesList[i]
        return ret
    _onClick: (event) =>
        if event.target.getAttribute('class')?.match(/course/) or true
            event.currentTarget = event.target
            @_onCourseClicked(event)
    _onCourseClicked: (event) =>
        elm = event.currentTarget
        #addClass(elm, 'highlight')
        console.log elm.courseHash, elm
        @selectCourse(elm.courseHash)
    # select a course and highlight all its prereqs
    selectCourse: (course) ->
        hash = hashCourse(course)
        prereqs = @coursePrereqs(hash)
        # highlight all the course nodes
        for _,c of @courses
            removeClass(c.elm, 'highlight')
        for prereq in prereqs
            addClass(@courses[prereq].elm, 'highlight')
        addClass(@courses[hash].elm, 'highlight')
        # highlight all the prereq arrows
        for elm in @svg.querySelectorAll('g.edge')
            removeClass(elm, 'highlight')
        for prereq in prereqs.concat([hash])
            id = sanitizeId(prereq)
            for elm in @svg.querySelectorAll("[target=#{id}]")
                addClass(elm, 'highlight')
        @createCourseSummary(course)
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
        infoArea = document.querySelector('#graphview-courseinfo')
        infoArea.querySelector('.name')?.textContent = hash
        infoArea.querySelector('.title')?.textContent = course.data.title
        for term in ['fall', 'spring', 'summer']
            elm = infoArea.querySelector(".#{term}")
            if course.data.terms_offered[term]
                removeClass(elm, "hidden")
            else
                addClass(elm, "hidden")
        infoArea.querySelector('.description')?.textContent = course.data.description

        # construct the prereq list
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
                    list.push "<li>#{hashCourse(c)}</li>"
                list.sort()
                elm?.innerHTML = list.join('')
                if list.length is 0
                    addClass(parent, "invisible")
                else
                    removeClass(parent, "invisible")
        else
            addClass(infoArea.querySelector('.prereq'), "invisible")
        # construct the prereq list
        parent = infoArea.querySelector(".coreq")
        elm = parent.querySelector('ul')
        list = []
        prereqs = years['coreq']
        for c in prereqs
            list.push "<li>#{hashCourse(c)}</li>"
        list.sort()
        elm?.innerHTML = list.join('')
        if list.length is 0
            addClass(parent, "invisible")
        else
            removeClass(parent, "invisible")


        



window.onload = ->
    loadSVG('testdata/test.svg', resize)
