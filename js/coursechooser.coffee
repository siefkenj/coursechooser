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
    for k,v of obj
        ret[k] = v
    return ret
# escape <,>,& in a string
htmlEncode = (str) ->
    str = '' + str
    str = str.replace('&','&amp;','g').replace('<','&lt;','g').replace('>','&gt;','g')
    return str
htmlUnencode = (str) ->
    str = '' + str
    # inefficient way to do it, but all the functions already exist
    return unescape(escapeJSON(str))

parseUrlHash = (hash) ->
    hash = hash.split(/[&?]/)
    ret = {hash: null, args: []}
    for h in hash
        if m = h.match(/^#[\w-]+/)
            ret.hash = m[0]
        if h.match('=')
            ret.args.push h.split('=')
    return ret

# escapes JSON so that it may be included in XML
# to decode use decodeURIComponent
escapeJSON = (str) ->
    if typeof str isnt 'string'
        throw new Error('escapeJSON must be called with a string only')
    htmlEscapeToChar = (str) ->
        if str.charAt(1) is '#'
            num = parseInt(str.slice(2,str.length - 1), 10)
            return String.fromCharCode(num)
        # list of html escape sequences from http://www.w3.org/TR/html4/sgml/entities.html
        # except &nbsp; has been replaced with a regular space
        htmlChars = {nbsp: 32, iexcl: 161, cent: 162, pound: 163, curren: 164, yen: 165, brvbar: 166, sect: 167, uml: 168, copy: 169, ordf: 170, laquo: 171, not: 172, shy: 173, reg: 174, macr: 175, deg: 176, plusmn: 177, sup2: 178, sup3: 179, acute: 180, micro: 181, para: 182, middot: 183, cedil: 184, sup1: 185, ordm: 186, raquo: 187, frac14: 188, frac12: 189, frac34: 190, iquest: 191, Agrave: 192, Aacute: 193, Acirc: 194, Atilde: 195, Auml: 196, Aring: 197, AElig: 198, Ccedil: 199, Egrave: 200, Eacute: 201, Ecirc: 202, Euml: 203, Igrave: 204, Iacute: 205, Icirc: 206, Iuml: 207, ETH: 208, Ntilde: 209, Ograve: 210, Oacute: 211, Ocirc: 212, Otilde: 213, Ouml: 214, times: 215, Oslash: 216, Ugrave: 217, Uacute: 218, Ucirc: 219, Uuml: 220, Yacute: 221, THORN: 222, szlig: 223, agrave: 224, aacute: 225, acirc: 226, atilde: 227, auml: 228, aring: 229, aelig: 230, ccedil: 231, egrave: 232, eacute: 233, ecirc: 234, euml: 235, igrave: 236, iacute: 237, icirc: 238, iuml: 239, eth: 240, ntilde: 241, ograve: 242, oacute: 243, ocirc: 244, otilde: 245, ouml: 246, divide: 247, oslash: 248, ugrave: 249, uacute: 250, ucirc: 251, uuml: 252, yacute: 253, thorn: 254, yuml: 255, fnof: 402, Alpha: 913, Beta: 914, Gamma: 915, Delta: 916, Epsilon: 917, Zeta: 918, Eta: 919, Theta: 920, Iota: 921, Kappa: 922, Lambda: 923, Mu: 924, Nu: 925, Xi: 926, Omicron: 927, Pi: 928, Rho: 929, Sigma: 931, Tau: 932, Upsilon: 933, Phi: 934, Chi: 935, Psi: 936, Omega: 937, alpha: 945, beta: 946, gamma: 947, delta: 948, epsilon: 949, zeta: 950, eta: 951, theta: 952, iota: 953, kappa: 954, lambda: 955, mu: 956, nu: 957, xi: 958, omicron: 959, pi: 960, rho: 961, sigmaf: 962, sigma: 963, tau: 964, upsilon: 965, phi: 966, chi: 967, psi: 968, omega: 969, thetasym: 977, upsih: 978, piv: 982, bull: 8226, hellip: 8230, prime: 8242, Prime: 8243, oline: 8254, frasl: 8260, weierp: 8472, image: 8465, real: 8476, trade: 8482, alefsym: 8501, larr: 8592, uarr: 8593, rarr: 8594, darr: 8595, harr: 8596, crarr: 8629, lArr: 8656, uArr: 8657, rArr: 8658, dArr: 8659, hArr: 8660, forall: 8704, part: 8706, exist: 8707, empty: 8709, nabla: 8711, isin: 8712, notin: 8713, ni: 8715, prod: 8719, sum: 8721, minus: 8722, lowast: 8727, radic: 8730, prop: 8733, infin: 8734, ang: 8736, and: 8743, or: 8744, cap: 8745, cup: 8746, int: 8747, there4: 8756, sim: 8764, cong: 8773, asymp: 8776, ne: 8800, equiv: 8801, le: 8804, ge: 8805, sub: 8834, sup: 8835, nsub: 8836, sube: 8838, supe: 8839, oplus: 8853, otimes: 8855, perp: 8869, sdot: 8901, lceil: 8968, rceil: 8969, lfloor: 8970, rfloor: 8971, lang: 9001, rang: 9002, loz: 9674, spades: 9824, clubs: 9827, hearts: 9829, diams: 9830, quot: 34, amp: 38, lt: 60, gt: 62, OElig: 338, oelig: 339, Scaron: 352, scaron: 353, Yuml: 376, circ: 710, tilde: 732, ensp: 8194, emsp: 8195, thinsp: 8201, zwnj: 8204, zwj: 8205, lrm: 8206, rlm: 8207, ndash: 8211, mdash: 8212, lsquo: 8216, rsquo: 8217, sbquo: 8218, ldquo: 8220, rdquo: 8221, bdquo: 8222, dagger: 8224, Dagger: 8225, permil: 8240, lsaquo: 8249, rsaquo: 8250, euro: 8364}
        code = str.slice(1, str.length - 1)
        num = htmlChars[code]
        # if we unescape a quote, make sure to re-escape it for JSON!
        if num is 34
            return "\\\""
        if num
            return String.fromCharCode(num)
        return str
    encodeUnicode = (str) ->
        # valid ascii range
        if 32 <= str.charCodeAt(0) <= 126
            return str
        return encodeURIComponent(str)

    # First we eliminate any of the html escape sequences that may be in our string.
    escaped = str.replace(/&.*?;/g, htmlEscapeToChar)
    # Next, escape <,>,& for xml
    for c in ['<', '>', '&']
        escaped = escaped.replace(c, encodeURIComponent(c), 'g')
    # encode any unicode characetrs
    escaped = escaped.replace(/./g, encodeUnicode)
    return escaped

# Attempts to return the number of en's wide
# str is by counting capital letters and wide letters
strWidthInEn = (str='') ->
    str = '' + str
    # capitals (excluding I) and m and w are the "wide"
    numWide = str.match(/[A-HJ-Zmw]/)?.length || 0
    numSkinny = str.match(/[Iijlt:]/)?.length || 0
    numSpaces = str.match(/[ ]/)?.length || 0
    # assume wide letters are 1.2x a normal letter
    # and skinny letters are .3x a normal letter
    return str.length + .2*numWide - .7*numSkinny - .2*numSpaces

titleCaps = (str) ->
    if not str
        return ''
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

# parses a string list of courses and returns an object {coures:[...], unknownCoures:[...], subjects:{...}}
# we parse in an extremely tolerant way. The string
#     math100,math 102, math 104, "math 202", engl 344,355, 295
# is paresed as the coureses math 100, math 102, mah 104, math 202, engl 344, engl 355, engl 295
# The string
#    math,engl
# is parsed as the subjects math, engl
# unknownCoures is a list of coures numbers whose subject could not be determined
parseCourseListString = (val) ->
    subjects = {}
    courses = []
    unknownCourses = []

    val = val.toUpperCase()
    val = val.replace(/([A-Z])(\d)/g, "$1 $2")
    val = val.split(/[^a-zA-Z0-9]+/)
    subject = null
    for v,i in val
        if v.length is 0
            continue
        if v.match (/^[a-zA-Z]/)
            subject = v
            # subjects contain only subjects for which we load every course.  ie. only lone
            # subjects. e.g. "math, biol" adds math and biol to the subject list,
            # but "math 100" shouldn't add math to the subject list
            if not val[i+1]?.match(/^\d/)
                subjects[subject] = true
        else
            if not subject?
                unknownCourses.push v
                continue
            courses.push {subject: subject, number: v}
    return {courses: courses, subjects: subjects, unknownCourses: unknownCourses}

# reparents an element with an optional animation
reparent = (elm, newParent, ops={}) ->
    if not ops.animate
        $(elm).appendTo(newParent)
        return

    elm = $(elm)
    newParent = $(newParent)
    oldOffset = ops.origin || elm.offset()
    elm.appendTo(newParent)
    newOffset = ops.target || elm.offset()

    tmp = elm.clone().appendTo('body')
    tmp.css({position: 'absolute', left: oldOffset.left, top: oldOffset.top, 'zIndex': 1000})
    elm.css({visibility: 'hidden'})
    tmp.animate {top: newOffset.top, left: newOffset.left},
        duration: 750
        easing: 'easeOutCubic'
        complete: ->
            elm.show()
            elm.css({visibility: 'visible'})
            tmp.remove()
            if ops.complete and not ops.complete.hasRun
                ops.complete()
                ops.complete.hasRun = true
    return

# prints the contents of '#welcome-steps'
printInstructions = ->
    printWindow = window.open('', 'Instructions', 'menubar=yes,status=1,width=350,height=150')
    printWindow.document.write("""<html><head><title>Instructions</title><link rel='stylesheet' href='css/coursechooser.css'></head>""")
    printWindow.document.write("""<body></body></html>""")
    printWindow.onafterprint = ->
        close = ->
            printWindow.close()
        printWindow.setTimeout(close, 0)
    newSteps = $('#welcome-steps').clone()
    # make sure the details are fully expanded
    newSteps.find('*').show()
    newSteps.find('a.more').hide()
    $(printWindow.document.body).html(newSteps)
    # TODO It appears the @media print styles do not show up at this point in Firefox...
    printWindow.print()

localStorageWrapper = (action='get', data) ->
    $.jStorage.reInit()
    if action is 'get'
        return $.jStorage.get('coursechooser')
    $.jStorage.set('coursechooser', data)

$(document).ready ->
    $('.course-status').buttonset().disableSelection()
    $('button').button()
    $('#department-list').combobox().combobox('value', '')
    $('#tabs,.tabs').tabs()
    ###
    $(document).tooltip
        show:
            effect: 'fade'
            delay: 1000
    ###

    # location.hash could have the form '#hash?other,stuff' so filter it out!
    locHash = parseUrlHash(window.location.hash)
    window.location.hash = window.location.hash || '#welcome' # we should start with the welcome hash so the back button works
    prepareWelcomePage()
    prepareNavMenu()

    window.courseManager = new CourseManager
    window.courses = window.courseManager.courses


    # based on the url hash arguments, decide to pre-show some subjects
    preloadSubjects = []
    for arg in locHash.args
        if arg[0] is 'load'
            preloadSubjects = preloadSubjects.concat(arg[1]?.split(/,/) || [])
    for subject in preloadSubjects
        window.courseManager.showCoursesOfSubject(subject)


    $('#show-courses').click ->
        errorMsgHash = {}

        subjects = {}
        courses = []
        unknownCourses = []

        try
            {courses, subjects, unknownCourses} = parseCourseListString($('#department-list').combobox('value'))
        catch e
            subjects[$('#department-list option:selected()').val()] = true

        for v of subjects
            createErrorCallback = (sub) ->
                return ->
                    errorMsgHash["Could not load subject '#{sub}'"] = true
                    $('#department-list').combobox('showError', (e for e of errorMsgHash).join('<br/>'))
            try
                window.courseManager.showCoursesOfSubject(v, {error: createErrorCallback(v), animate: 'slow'})
            catch e
                console.log e

        for c in courses
            createErrorCallback = (sub) ->
                return ->
                    errorMsgHash["Could not load course '#{sub.subject} #{sub.number}'"] = true
                    $('#department-list').combobox('showError', (e for e of errorMsgHash).join('<br/>'))
            createDisplayCallback = (c) ->
                return ->
                    try
                        window.courseManager.ensureDisplayedInYearChart(c, {error: createErrorCallback(c), animate: 'slow'})
                    catch e
                        console.log e
            try
                window.courseManager.loadSubjectData(c.subject, createDisplayCallback(c), {error: createErrorCallback(c), animate: 'slow'})
            catch e
                console.log e
        for c in unknownCourses
            errorMsgHash["Could not determine subject code for course '#{c}'"] = true
            $('#department-list').combobox('showError', (e for e of errorMsgHash).join('<br/>'))
    # whenever we are doing ajax, let's spin the throbber since
    # it primarly happens whenever we are loading courses in this view
    $('#show-courses .throbber').ajaxStart(->
        $(@).show()
    ).ajaxComplete(->
        $(@).hide()
    )
    $('#hide-courses').click ->
        subjects = {}
        courses = []
        unknownCourses = []
        try
            {courses, subjects, unknownCourses} = parseCourseListString($('#department-list').combobox('value'))
        catch e
            subjects[$('#department-list option:selected()').val()] = true
        for v of subjects
            window.courseManager.hideCoursesOfSubject(v, {animate: 'slow'})
        for c in courses
            window.courseManager.hideCourse(c, {animate: 'slow'})

    # make the years droppable
    $('.year').droppable
        hoverClass: 'highlight'
        tolerance: 'pointer'
        drop: (event, ui) ->
            courses = this.getElementsByClassName('courses')[0]
            courses.appendChild(ui.draggable[0])
            window.courseManager.courseMoved(ui.draggable[0].course)
            window.courseManager.selectCourse(ui.draggable[0].course)

    # setup the electives area
    $('#create-new-electives').click ->
        elective = new ElectivesButtonEditor({title:'Electives'}, window.courseManager)
        electiveButton = new ElectivesButton(elective)
        $('#electives-list').append(elective.getButton())
        $('.year1 .courses').append(electiveButton.getButton())
        window.courseManager.addCourse(electiveButton)
        window.courseManager.sortableCourses[electiveButton] = electiveButton
        window.courseManager.addCourse(elective)
        window.courseManager.makeCourseButtonDraggable(electiveButton)
        window.courseManager.makeElectivesButtonDroppable(electiveButton)
        window.courseManager.makeElectivesButtonClickable(electiveButton)
        window.courseManager.makeElectivesButtonClickable(elective)

    # set up the load and save buttons
    $('#save').click ->
        window.courseManager.updateGraphState()
        baseName = (window.courseManager.graphState.title || "course-map").replace(/\W/g,'_')
        # if we are currently looking at a preview, save a visual version, otherwise save
        # the json
        name = baseName + ".json"
        data = window.courseManager.graphState.toJSON()
        mimeType = 'application/json'
        if $('a[page=#preview]').hasClass('active')
            name = baseName + '.svg'
            # clone our svg.  We don't want these inlined styles to be persistent after we've saved
            clonedSvg = window.courseManager.svgManager.svgGraph.svg.cloneNode(true)

            # we don't wany any highlight's or selection to show up when our
            # styles are inlined.  Unfortunately, we cannot use jQuery's removeClass
            # on SVG nodes.
            for elm in $(clonedSvg).find('.highlight')
                SVGGraphManager.utils.removeClass(elm, 'highlight')
            for elm in $(clonedSvg).find('.selected')
                SVGGraphManager.utils.removeClass(elm, 'selected')
            window.courseManager.svgManager.svgGraph.inlineDocumentStyles(clonedSvg)
            window.courseManager.svgManager.svgGraph.addCDATA
                svg: clonedSvg
                elmName: 'coursemapper'
                data: escapeJSON(window.courseManager.graphState.toJSON())
            # set our width/height so we print properly and we convert to a pdf letter size
            clonedSvg.setAttribute('width', '8.5in')
            clonedSvg.setAttribute('height', '11in')
            clonedSvg.setAttribute('preserveAspectRatio', 'xMinYMin meet')

            if parseFloat(clonedSvg.getAttribute('aspect')) > 8.5/11
                clonedSvg.setAttribute('width', '8.5in')
            data = $('<div></div>').append(clonedSvg).html()
            mimeType = 'image/svg+xml'
        downloadManager = new DownloadManager(name, data, mimeType)
        downloadManager.download()
    $('#load').click ->
        # fallback 'cause we cannot trigger a click on a file input...
        dialog = $('''
            <div>
            <h3>Browse for the file you wish to upload</h3>
            <input type="file" id="files" name="files[]" accept="application/json" />
            </div>''')
        $(document.body).append(dialog)
        dialog.dialog({ height: 300, width: 500, modal: true })
        dialog.find('input').change (event) ->
            files = event.target.files
            FileHandler.handleFiles(files)
            dialog.remove()
    $('#new').click ->
        clearAll = ->
            window.courseManager.clearAll()
            $('#program-info input').val('')
            showPage('#welcome')
        dialog = $('''
            <div title="Start a new Program?">
            <p><span class="ui-icon ui-icon-alert" style="float: left; margin: 0 7px 20px 0;"></span>
            Warning: all unsaved data will be lost and an
            empty program will be presented.</p>
            </div>''')
        $(document.body).append(dialog)
        dialog.dialog
            height: 200
            modal: true
            resizable: false
            buttons:
                'Continue': ->
                    dialog.remove()
                    clearAll()
                'Cancel': ->
                    dialog.remove()
    ZOOM_FACTOR = 1.25
    $('#zoom-preview-in').click ->
        svg = $('#map-container svg')[0]
        width = parseFloat svg.getAttribute('width')
        height = parseFloat svg.getAttribute('height')
        svg.setAttribute('width', width*ZOOM_FACTOR)
        svg.setAttribute('height', height*ZOOM_FACTOR)
    $('#zoom-preview-out').click ->
        svg = $('#map-container svg')[0]
        width = parseFloat svg.getAttribute('width')
        height = parseFloat svg.getAttribute('height')
        svg.setAttribute('width', width/ZOOM_FACTOR)
        svg.setAttribute('height', height/ZOOM_FACTOR)

    $('#toggleEdge').click ->
        svgManager = window.courseManager.svgManager
        if not (svgManager and svgManager.selected[0] and svgManager.selected[1])
            return
        else
            elm1 = svgManager.selected[0].getAttribute('id').replace('-',' ')
            elm2 = svgManager.selected[1].getAttribute('id').replace('-',' ')
            edge = window.courseManager.graphState.edges[[elm1,elm2]]
            edge = edge || window.courseManager.graphState.edges[[elm2,elm1]]
            if edge
                # if we have an exising edge and its invisible, turn it visible
                # and visa versa.  If we turn a user-created edge invisible, also
                # delee it.
                if edge.properties.style?.match(/invis/)
                    edge.properties.style = ''
                else
                    edge.properties.style = 'invis'
                    if not edge.properties.autoGenerated
                        window.courseManager.graphState.removeEdge(edge.edge)
            else
                window.courseManager.graphState.addEdge([elm1, elm2])

            updatePreview
                preserveSelection: true
                start: =>
                    $(@).find('span').append('<img class="throbber" src="image/ajax-loader.gif"/>')
                finish: =>
                    $(@).find('.throbber').remove()
            return
    $('#toggleCoreq').click ->
        svgManager = window.courseManager.svgManager
        if not (svgManager and svgManager.selected[0] and svgManager.selected[1])
            return
        else
            elm1 = svgManager.selected[0].getAttribute('id').replace('-',' ')
            elm2 = svgManager.selected[1].getAttribute('id').replace('-',' ')
            edge = window.courseManager.graphState.edges[[elm1,elm2]]
            edge = edge || window.courseManager.graphState.edges[[elm2,elm1]]
            if not edge
                return

            edge.properties.coreq = not edge.properties.coreq

            updatePreview
                preserveSelection: true
                start: =>
                    $(@).find('span').append('<img class="throbber" src="image/ajax-loader.gif"/>')
                finish: =>
                    $(@).find('.throbber').remove()
            return
    # TODO Doesnt work!
    $('#reverseEdge').click ->
        svgManager = window.courseManager.svgManager
        if not (svgManager and svgManager.selected[0] and svgManager.selected[1])
            return
        else
            elm1 = svgManager.selected[0].getAttribute('id').replace('-',' ')
            elm2 = svgManager.selected[1].getAttribute('id').replace('-',' ')
            edge = window.courseManager.graphState.edges[[elm1,elm2]]
            edge = edge || window.courseManager.graphState.edges[[elm2,elm1]]
            if edge
                # if we have an exising edge and its invisible, turn it visible
                # and visa versa.  If we turn a user-created edge invisible, also
                # delee it.
                if edge.properties.style?.match(/invis/)
                    edge.properties.style = ''
                else
                    edge.properties.style = 'invis'
                    if not edge.properties.autoGenerated
                        window.courseManager.graphState.removeEdge(edge.edge)
                window.courseManager.graphState.addEdge([elm2, elm1])

            updatePreview
                preserveSelection: true
                start: =>
                    $(@).find('span').append('<img class="throbber" src="image/ajax-loader.gif"/>')
                finish: =>
                    $(@).find('.throbber').remove()
            return

    # set up autosaves and autoloads
    saveGraph = ->
        window.courseManager.updateGraphState()
        data = window.courseManager.graphState.toJSON()
        localStorageWrapper('set', data)
        return
    $(window).bind 'beforeunload', ->
        saveGraph()
    window.setInterval(saveGraph, 1000*5*60)     # autosave every 5 minutes
    window.setTimeout (->
        data = localStorageWrapper('get')
        if data
            try
                window.courseManager.loadGraph data
                # make sure the welcome page is updated after any previous data has been loaded
                #XXX ugly hack!
                window.setTimeout(updateWelcomePage, 100)
            catch e
                console.log 'could no load local storage data'), 0

    # we'd like to show up on the correct tab when we relaod with a hash
    window.onhashchange?()

prepareWelcomePage = ->
    makeLinkShow = (link, elm) ->
        show = ->
            elm.show()
            link.html("Hide Details")
        hide = ->
            elm.hide()
            link.html("Show Details")
        link.toggle(show, hide)
    for elm in $("#welcome li div.more")
        $elm = $(elm)
        $elm.hide()
        $link = $('<a class="more" href="javascript: void 0;">Show Details</a>').appendTo($elm.parent().find('p')[0])
        makeLinkShow($link, $elm)

    $('#goto-course-chooser').click ->
        showPage('#course-chooser', {animate: true, complete: (-> $('#show-courses').trigger('click'))})
    $('#welcome-new-program').click ->
        $('#new').click()

    $('#print-instructions').click(printInstructions)

    updateWelcomePage()
    return
# shows and hides things on the welcome page (such as next/new button)
# based upon the current state.
updateWelcomePage = ->
    # if there are any sortable courses, assume we are working off an existing
    # program, otherwise assume a new and empty program
    console.log window.courseManager?.sortableCourses
    if window.courseManager?.sortableCourses and Object.keys(window.courseManager.sortableCourses).length is 0
        $('#welcome-new').hide()
        $('#welcome-next').show()
    else
        $('#welcome-new').show()
        $('#welcome-next').hide()

prepareNavMenu = ->
    makeLinkShow = (link, target) ->
        link.click ->
            showPage(target, {animate: false})

    for elm in $('#menu-nav a')
        elm = $(elm)
        target = elm.attr('href')
        #elm.attr({href: 'javascript: void 0;'})
        makeLinkShow(elm, target)

    # make sure the back button works--that is when the index.html#foo changes,
    # make the appropriate page display
    window.onhashchange  = ->
        hash = parseUrlHash(window.location.hash).hash
        $("a[page=#{hash}]").click()
    return

showPage = (page, ops={}) ->
    if typeof page isnt 'string'
        throw new Error("showPage expects page to be a string, not #{page}")
    # set the nav menu to be properly highlighted
    for elm in $('#menu-nav a')
        elm = $(elm)
        if elm.attr('page') is page
            elm.addClass('active')
        else
            elm.removeClass('active')
    target = $(page)

    switch page
        when '#welcome'
            updateWelcomePage()
        when '#preview'
            onPreviewPageShow()

    # if we're not animating, we don't need to do
    # anything fancy, so just ensure our container elements
    # are all filled
    if not ops.animate
        $('.page').hide()
        for elm in target.find('.container')
            id = elm.getAttribute('contains')
            reparent($(id), elm, ops)
        target.show()
        return

    # if we're animating, we need to find the position of each element
    # that's moving to the new page befor we hide anything
    currentPageContainers = (elm.getAttribute('contains') for elm in $($('.page:visible')).find('.container'))
    newPageContainers = (elm.getAttribute('contains') for elm in target.find('.container'))
    needsAnimation = []
    doesntNeedAnimation = []
    for elm in newPageContainers
        if currentPageContainers.indexOf(elm) >= 0
            needsAnimation.push elm
        else
            doesntNeedAnimation.push elm
    offsets = {}
    for elm in needsAnimation
        offsets[elm] = $(elm).offset()

    for elm in doesntNeedAnimation
        container = target.find(".container[contains=#{elm}]")
        reparent(elm, container, ops)
    $('.page').hide()
    target.show()
    for elm in needsAnimation
        container = target.find(".container[contains=#{elm}]")
        reparent(elm, container, {animate: true, origin: offsets[elm], complete: ops.complete})

    # special actions to be taken on particular pages
    return

updatePreview = (ops={preserveSelection: false}) ->
    # we may want to show a progress indicator
    ops.start?()

    render = ->
        # any time we are rendering, let's show the status indicator
        $('#preview-status .message-text').text("Updating Graph")
        $('#preview-status').show()
        dotCode = window.courseManager.createDotGraph()
        window.Viz.onmessage = (event) ->
            data = event.data
            if data.type isnt 'graph'
                throw new Error('Need the webworker to return graph type!')
            xdotCode = data.message
            # there are some warnings in the xdot code, but they are printed
            # at the beginning, so filter them away
            xdotCode = xdotCode.slice(xdotCode.indexOf('digraph {'))
            ast = DotParser.parse(xdotCode)
            svgManager = new SVGGraphManager(new SVGDot(ast), window.courseManager.graphState)

            oldSvgManager = window.courseManager.svgManager
            oldSelection = []
            if oldSvgManager and ops.preserveSelection
                for elm in oldSvgManager.selected || [] when elm
                    oldSelection.push elm.getAttribute('id')
            window.courseManager.initializeSVGManager(svgManager)
            # restore all of the previous selection.  This list will be empty
            # if preserveSelection == false
            for id,i in oldSelection
                svgManager.select $(svgManager.svg).find("##{id}")[0]

            #svgGraph = new SVGDot(ast)
            #svgGraph.render()
            preview = svgManager.svg
            aspect = parseFloat preview.getAttribute('aspect')
            if aspect
                width = $('#map-container').width()
                height = $('#map-container').height()
                #if width / aspect > height
                #    width = height * aspect
                preview.setAttribute('width', Math.round(width))
                preview.setAttribute('height', Math.round(width/aspect))

            $('#map-container').html preview

            ops.finish?()
            $('#preview-status').fadeOut('fast')
        window.Viz.postMessage(dotCode)
    window.setTimeout(render, 0)

onPreviewPageShow = ->
    if not window.Viz?
        window.Viz = new Worker('js/viz-worker.js')
        window.Viz.onmessage = (event) ->
            data = event.data
            if data.type is 'status' and data.message is 'viz-loaded'
                $('#preview-status').hide()
                $('#map-holder').show()
                updatePreview()

        ###
        #$('#preview-status').html 'loading graphviz library'
        $.getScript 'js/viz-2.26.3.js', ->
            $('#preview-status').hide()
            $('#map-holder').show()
            updatePreview()
        ###
    else
        window.setTimeout(updatePreview, 0)

class SVGGraphManager

    # jquery's functions don't work on svg elements, so we'll use our own
    addClass = (elm, cls) ->
        oldCls = elm.getAttribute('class')
        if oldCls.split(/\s+/).indexOf(cls) >= 0
            return
        elm.setAttribute('class', oldCls + ' ' + cls)
    removeClass = (elm, cls) ->
        oldCls = elm.getAttribute('class')
        newCls = (c for c in oldCls.split(/\s+/) when c isnt cls)
        elm.setAttribute('class', newCls.join(' '))
    sanitizeId = (str) ->
        return (''+str).replace(/\W+/g,'-')

    @utils:
        addClass: addClass
        removeClass: removeClass

    constructor: (@svgGraph, @graphState) ->
        @svgGraph.render()
        @svg = @svgGraph.svg
        @$svg = $(@svgGraph.svg)
        @addReferenceToCourseToNodes()
        @$svg.find('.node').click (event) =>
            elm = event.currentTarget
            if elm.isElectivesNode
                course = @graphState.clusters[elm.courseHash]
                @electivesNodeClicked(course.cluster)
            else
                course = @graphState.nodes[elm.courseHash]
                @courseClicked(course.course)

        @selected = [null, null]    # currently selected nodes
    # adds a .courseHash expando property to all svg nodes corresponding to a course
    addReferenceToCourseToNodes: ->
        for hash of @graphState.nodes
            elm = @$svg.find("##{sanitizeId(hash)}")[0]
            if elm
                elm.courseHash = hash
        for hash of @graphState.clusters
            elm = @$svg.find("##{sanitizeId(hash)}")[0]
            if elm
                elm.courseHash = hash
                elm.isElectivesNode = true
    selectEdgeBetween: (elm1, elm2) ->
        id1 = elm1.getAttribute('id')
        id2 = elm2.getAttribute('id')
        for edge in @$svg.find("[target=#{id1}][origin=#{id2}]")
            addClass(edge, 'highlight')
        for edge in @$svg.find("[target=#{id2}][origin=#{id1}]")
            addClass(edge, 'highlight')

    select: (elm) ->
        # special behavior when clicking an electivesNode
        if elm.isElectivesNode
            @selected[0] = elm
            addClass(elm, 'selected')
            @selectionChanged?()
            return
        # if we have any electivesNodes selected and we click something else, we want
        # to deselect them instead of adding them to the queue.
        if @selected[0]?.isElectivesNode or @selected[1]?.isElectivesNode
            @deselectAll()

        # if the queue is full, cyclically rotate
        if @selected[0] and @selected[1]
            @deselct(@selected[0])
            @selected[0] = @selected[1]
            @selected[1] = elm
        else if @selected[0]
            @selected[1] = elm
        else
            @selected[0] = elm
        addClass(elm, 'selected')

        if @selected[0] and @selected[1]
            @selectEdgeBetween(@selected[0], @selected[1])
        @selectionChanged?()
    deselct: (elm) ->
        i = @selected.indexOf(elm)
        if i >= 0
            @selected[i] = null
        removeClass(elm, 'selected')
        @selectionChanged?()
    deselectAll: ->
        for elm in @$svg.find('.selected')
            removeClass(elm, 'selected')
        for elm in @$svg.find('.highlight')
            removeClass(elm, 'highlight')
        @selected[0] = null
        @selected[1] = null
        @selectionChanged?()

    courseClicked: (course) ->
        clickedNode = $("##{sanitizeId(BasicCourse.hashCourse(course))}")[0]

        for edge in @$svg.find('.edge.highlight')
            removeClass(edge, 'highlight')

        if @selected.indexOf(clickedNode) >= 0
            @deselct(clickedNode)
            return
        # if deselected and now the list is [null, item], permute it to [item, null]
        if @selected[1] and not @selected[0]
            @selected[0] = @selected[1]
            @selected[1] = null
        @select(clickedNode)

    electivesNodeClicked: (course) ->
        clickedNode = $("##{sanitizeId(BasicCourse.hashCourse(course))}")[0]
        @deselectAll()

        @select(clickedNode, true)

    highlightPrereqPath: (course) ->
        for elm in @$svg.find('.highlight')
            removeClass(elm, 'highlight')

        # highight the node and all its anscestors
        highlight = (node) =>
            addClass($(node)[0], "highlight")
            id = $(node).attr('id')
            for arrow in @$svg.find("[target=#{id}]")
                addClass(arrow, "highlight")
                highlight($("##{arrow.attr('origin')}"))
        highlight("##{course.subject}-#{course.number}")

###
# Class to manage and keep the sync of all course on the webpage
# and their state.
###
class CourseManager
    DISPLAYABLE_STATES: ['required', 'elective', 'core']
    constructor: ->
        @courses = {}
        @courseData = {}
        @sortableCourses = {}   # all the courses that are displayed in the year chart (and so are sortable)
        @sortableCoursesStateButtons = {}
        @loadedSubjects = {}
        @loadingStatus = {}
        @onSubjectLoadedCallbacks = {}
        @graphState = new Graph
        @mostRecentTerm = ''    # we'd only like to show course availability for the most recent 2 years (6 most recent terms)
    # Based make sure @graphState reflects everything
    # that is in the year chart.
    updateGraphState: ->
        @graphState.title = $('#program-info input').val()
        @graphState.mostRecentTerm = @mostRecentTerm
        # returns whether or not a single course should be inlcuded in the graph
        # and if given a list, will filter the list so only courses that should be displayed remain
        filterDisplayable = (list) =>
            if not list
                return list
            # are we an array?
            if not list.length?
                for state in @DISPLAYABLE_STATES
                    return true if list.state?[state]
                return false
            return (c for c in list when filterDisplayable(c))

        # get a list of all the courses that should show up and what year
        # they should be showing up
        courses = {}
        for year in [1..4]
            for elm in $(".year#{year} .course")
                hash = BasicCourse.hashCourse({subject: elm.getAttribute('subject'), number: elm.getAttribute('number')})
                course = @sortableCourses[hash]
                if filterDisplayable(course)
                    courses[hash] =
                        course: course
                        year: year
        # gather all the clusters of electives that should show up
        clusters = {}
        for year in [1..4]
            for cluster in $(".year#{year} .electives-block")
                clusterHash = BasicCourse.hashCourse({subject: cluster.getAttribute('subject'), number: cluster.getAttribute('number')})
                clusters[clusterHash] =
                    cluster: @sortableCourses[clusterHash]
                    year: year
                    courses: []
                for elm in $(cluster).find('.course')
                    hash = BasicCourse.hashCourse({subject: elm.getAttribute('subject'), number: elm.getAttribute('number')})
                    course = @sortableCourses[hash]
                    if filterDisplayable(course)
                        clusters[clusterHash].courses.push course
        @graphState.nodes = courses
        @graphState.clusters = clusters
        @graphState.pruneOrphanedEdges()
        @graphState.generateEdges()

        return @graphState

    # clears all loaded courses and removes their DOM nodes.
    # this function should make CourseManager reset to a pristine
    # state
    clearAll: ->
        for hash,courses of @courses
            for course in courses
                course.removeButton?()
            @courses[hash] = null
        @courses = {}
        @courseData = {}
        @sortableCourses = {}   # all the courses that are displayed in the year chart (and so are sortable)
        @sortableCoursesStateButtons = {}
        @loadedSubjects = {}
        @loadingStatus = {}
        @onSubjectLoadedCallbacks = {}
        @graphState.clearAll()


    # takes in JSON representation of a graph and
    # loads all relavent courses, etc.
    loadGraph: (str) ->
        @clearAll()
        # we'll update graph state and from that repopulate the dom, etc. appropriately
        @graphState.fromJSON(str)

        $('#program-info input').val(@graphState.title)

        courseLoadCallback = {}
        #creates a function that reparents course to electivesBlock
        createCourseLoadCallback = (electivesBlock) =>
            ret = (course) =>
                electivesBlock.addCourse(course)
                @updateElectivesButton(electivesBlock)
            return ret

        # load the elective blocks first so they can be populated
        # when ensureDisplayedInYearChart is called
        for _,cluster of @graphState.clusters
            elective = new ElectivesButtonEditor(cluster.cluster, @)
            electiveButton = new ElectivesButton(elective)
            $('#electives-list').append(elective.getButton())
            $(".year#{cluster.year} .courses").append(electiveButton.getButton())
            @addCourse(electiveButton)
            @sortableCourses[electiveButton] = electiveButton
            @addCourse(elective)
            @makeCourseButtonDraggable(electiveButton)
            @makeElectivesButtonDroppable(electiveButton)
            @makeElectivesButtonClickable(electiveButton)
            @makeElectivesButtonClickable(elective)
            for course in cluster.courses
                hash = BasicCourse.hashCourse(course)
                courseLoadCallback[hash] = createCourseLoadCallback(electiveButton)

        for _,node of @graphState.nodes
            course = node.course
            hash = BasicCourse.hashCourse(course)
            @ensureDisplayedInYearChart(course, {state: course.state, year: node.year, load: courseLoadCallback[hash]})

        # display the graph preview when the preview page is active
        if $('a[page=#preview]').hasClass('active')
            #XXX We need to delay
            window.setTimeout(updatePreview, 1000)
        return @graphState
    initializeSVGManager: (svgManager) ->
        idToCourse = (id) ->
            [subject, number] = id.split('-')
            return {subject, number}

        @svgManager = svgManager
        @svgManager.selectionChanged = =>
            # special behavior for when we click an electives block.
            # We want to be able to edit its extra properties.
            if svgManager.selected[0]?.isElectivesNode
                elm = svgManager.selected[0]
                course = @sortableCourses[elm.courseHash]
                course.data = course.data || {}
                $('#preview-tabs').tabs('select', '#tab-electives-graphical')
                $('#currently-selected-electivesNode').html course.title
                @bindElectivesDescription(course)
                return

            $('#preview-tabs').tabs('select', '#tab-edges')
            if not (svgManager.selected[0] and svgManager.selected[1])
                elm = 0
                if svgManager.selected[0]
                    elm = svgManager.selected[0].getAttribute('id')
                if svgManager.selected[1]
                    elm = svgManager.selected[1].getAttribute('id')
                course1 = window.courseManager.createCourseButton idToCourse(elm) if elm
            else
                course1 = idToCourse(svgManager.selected[0].getAttribute('id'))
                course2 = idToCourse(svgManager.selected[1].getAttribute('id'))
                course1 = window.courseManager.createCourseButton(course1)
                course2 = window.courseManager.createCourseButton(course2)

                edge = window.courseManager.graphState.edges[[course1,course2]]
                # if we have an edge facing the other way, assume the user wanted
                # to select that edge in the correct order
                if not edge and window.courseManager.graphState.edges[[course2,course1]]
                    edge = window.courseManager.graphState.edges[[course2,course1]]
                    tmp = course1
                    course1 = course2
                    course2 = tmp
            # set up the graphical part of selection
            if course1
                $('#course1 .course-container').html course1.$elm
                $('#course1 .course-standin').hide()
            else
                $('#course1 .course-container').html ''
                $('#course1 .course-standin').show()
            if course2
                $('#course2 .course-container').html course2.$elm
                $('#course2 .course-standin').hide()
            else
                $('#course2 .course-container').html ''
                $('#course2 .course-standin').show()

            toggleEdge = $('#toggleEdge')
            toggleCoreq = $('#toggleCoreq')
            reverseEdge = $('#reverseEdge')
            if course1 and course2
                toggleEdge.button('enable')
            else
                toggleEdge.button('disable')

            # non-existent edges or invisible edges should not be shown
            if not edge or edge.properties.style?.match(/invis/)
                $('#edge1').attr({class: 'noArrow'})
                toggleEdge.find('span').text toggleEdge.attr('op1')
                toggleCoreq.button('disable')
                reverseEdge.button('disable')
            else
                toggleCoreq.button('enable')
                toggleEdge.find('span').text toggleEdge.attr('op2')
                if edge.properties.coreq
                    $('#edge1').attr({class: 'coreqArrow'})
                    toggleCoreq.find('span').text toggleCoreq.attr('op2')
                    reverseEdge.button('disable')
                else
                    $('#edge1').attr({class: 'prereqArrow'})
                    toggleCoreq.find('span').text toggleCoreq.attr('op1')
                    reverseEdge.button('enable')
            return

        @svgManager.selectionChanged()

    # updates the state of all instances of a particular course
    updateCourseState: (course, state, ops={updatePrereqs: true}) ->
        hash = BasicCourse.hashCourse(course)
        for c in (@courses[hash] || [])
            if not c.selectable
                state = dupObject(state)
                delete state.selected
            c.setState(state)
        if ops.updatePrereqs
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
    removeElective: (course) ->
        if @sortableCourses[course]
            # reparent all of the electives children
            for _,c of @sortableCourses[course].courses
                @sortableCourses[course].$elm.parent().append(c.$elm)
                @updateCourseState(c, {required:false, elective:false})
            @sortableCourses[course].removeCourse(c, {detach: false})
            delete @sortableCourses[course]
        for c in @courses[course]
            c.removeButton()
        delete @courses[course]

    removeAllCourseInstances: (course) ->
        hash = BasicCourse.hashCourse(course)
        for c in @courses[hash]
            # if we are an elective, we have a special delete procedure
            if c instanceof Electives
                @removeElective(course)
                break
            c.removeButton()
        delete @courses[hash]
        delete @sortableCourses[hash]
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
    #
    # returns a list of hashes of all courses that button has as children
    updateElectivesButton: (button) ->
        data = button.getValues()
        # we will sync the courses manually, we don't want to have a shallow copy of the courses object!
        delete data.courses

        for electiveButton in (@courses[button] || [])
            # make sure each ElectivesButton has a list of the courses that button does
            # and only those courses
            diff = symmetricDiffObjects(button.courses, electiveButton.courses)
            for hash,course of diff['missing']
                newCourse = @createCourseButton(course, {clickable: true, restrictions: 'elective'})
                electiveButton.addCourse(newCourse)
            for hash,course of diff['excess']
                electiveButton.removeCourse(course)

            electiveButton.update(data)
        return (k for k of button.courses)

    # out of sortableCourses, ensures only course has the selected state
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
            @updateCourseState(c, c.state, {updatePrereqs: false})
        if not selectedCourse
            return

        if selectedCourse instanceof BasicCourse
            # set up the course info area for the selected course
            stateButtons = @sortableCoursesStateButtons[selectedCourse]
            if not stateButtons
                stateButtons = @createCourseStateButton(selectedCourse)
            stateButtons.setRestrictions(selectedCourse.restrictions)
            $('.course-info .course-name .course-number').html selectedCourse.hash
            $('.course-info .course-name .course-title').html titleCaps(('' + selectedCourse.data.title).toLowerCase())
            # if we don't detach first, jquery removes all bound events and ui widgets, etc.
            $('.course-info .course-state').children().detach()
            $('.course-info .course-state').html stateButtons.elm
            $('.course-info .prereq-area').html PrereqUtils.prereqsToDivs(stateButtons.prereqs, @)
            $('.course-info .terms-area').html CourseUtils.historyToDivs(selectedCourse.getTermsOffered(@mostRecentTerm, 2))
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
                course.setTooltip(titleCaps(course.data.title))
                course.wasSynced = true
            @loadSubjectData(course.subject, updateCourse)
        if ops.clickable
            @makeCourseButtonClickable(course, ops)
        if ops.draggable
            @makeCourseButtonDraggable(course, ops)
        if ops.restrictions
            course.restrictions = ops.restrictions
        @addCourse(course)
        @initButtonState(course)
        return course
    # makes it so that when you click the button,
    # it cycles through the states and ensures all instances
    # are appropriately synced
    makeCourseButtonClickable: (button, ops={}) ->
        # if we're selectable we should be keyboard navigatable too
        if ops.selectable
            button.selectable = true
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
            evt.stopPropagation()
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
            newState = CourseManager.toggleState(button.state, button.restrictions)
            # we need to make sure that the course appears in the yearchart if this option
            # is set
            if ops.insertOnClick
                try
                    @ensureDisplayedInYearChart(button)
                catch e
                    console.log e
            @updateCourseState(button, newState)
    makeCourseButtonDraggable: (button, ops={}) ->
        $(button.getButton()).draggable
            #appendTo: '#course-chooser'
            containment: '#main'
            scroll: true
            helper: 'clone'
            revert: 'invalid'
            distance: '25'
            opacity: 0.7
            zIndex: 1000

    # makes the drop area of an ElectivesButton a drop target. If
    # clone is truthy instead of moving the course, a copy of the
    # course will be created.
    makeElectivesButtonDroppable: (button, ops={clone: false}) ->
        button.getButton()
        button.$coursesDiv.droppable
            #TODO this seems to mess up the parent sometimes!
            greedy: true
            hoverClass: 'highlight'
            tolerance: 'pointer'
            accept: (ui) ->
                return ui[0].course instanceof BasicCourse
            drop: (event, ui) =>
                if not ui.draggable[0].course
                    return false
                button.addCourse(ui.draggable[0].course)
                # calling the courseMoved method will ensure that
                # all electivesButtons are synced up and updated with
                # their new contents
                @courseMoved(ui.draggable[0].course)
                @selectCourse(ui.draggable[0].course)
                # when we drop a course on an electives block, assume
                # we want it automatically to be marked as an elective
                @updateCourseState(ui.draggable[0].course, {required:false, elective:true})
    makeElectivesButtonClickable: (button, ops={}) ->
        button.$elm.click(=> @selectCourse(button))

    # this method is called whenever a course changes levels or
    # gets added or removed from an elective's block
    courseMoved: (course) ->
        electivesChildren = []
        # see if any of our electivesButtons have changed
        # and if so, update them
        for hash,c of @sortableCourses
            if c instanceof ElectivesButton
                children = @updateElectivesButton(c)
                electivesChildren = electivesChildren.concat children
        # we now have a list of all child courses of electives.  update course's
        # state accordingly
        electivesChildren = (BasicCourse.hashCourse(c) for c in electivesChildren)
        state = dupObject(course.state)
        if electivesChildren.indexOf(BasicCourse.hashCourse(course)) >= 0
            course.restrictions = 'elective'
            if state.required
                state.required = false
                state.elective = true
                @updateCourseState(course, state)
        else
            course.restrictions = 'nonelective'
            if state.elective
                state.required = true
                state.elective = false
                @updateCourseState(course, state)
        return

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
    @toggleState: (state, restrictions) ->
        ret =
            required: false
            elective: false
        switch restrictions
            # toggle between elective and none
            when 'elective'
                if not state.elective
                    ret.elective = true
            # toggle between required and none
            when 'nonelective'
                if not state.required
                    ret.required = true
            # toggle required -> elective -> none
            else
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
    # performs an ajax call to load a subject.
    # If loadSubjectData is called multiple times before the ajax call
    # has finished, the callbacks are queued and executed after the ajax call
    # finishes. (the ajax call is only made once, so call this function as often as you like)
    loadSubjectData: (subject, callback, ops={}) ->
        @onSubjectLoadedCallbacks[subject] = @onSubjectLoadedCallbacks[subject] || []
        @onSubjectLoadedCallbacks[subject].push callback
        doAllCallbacks = =>
            while func = @onSubjectLoadedCallbacks[subject].shift()
                func()
            @loadingStatus[subject] = 'loaded'

        if @loadedSubjects[subject] and not ops.force
            doAllCallbacks()
            return
        if @loadingStatus[subject] is 'loading' and not ops.force
            return
        @loadingStatus[subject] = 'loading'

        error = (e) ->
            console.log 'ajax error'
            throw e

        ajaxArgs =
            url: "course_data/#{subject}.json"
            dataType: 'json'
            success: @courseDataLoaded
            error: [(=> @loadingStatus[subject] = 'failed'), (ops.error || error)]
            complete: doAllCallbacks
        $.ajax ajaxArgs

    courseDataLoaded: (data, textState, jsXHR) =>
        for c in data
            hash = BasicCourse.hashCourse(c)
            @courseData[hash] = c
            # when the data was scraped it may contain html escape characters like '&amp;'
            # remove all of these so they won't show up anywhere accidentally.
            @courseData[hash].title = htmlUnencode(@courseData[hash].title)
            @courseData[hash].description = htmlUnencode(@courseData[hash].description)

            @loadedSubjects[c.subject] = true
            if c.terms_offered
                for term of c.terms_offered when term > @mostRecentTerm
                    @mostRecentTerm = term
    # shows courses from a particular department.  If buttons
    # already exist for the department, those buttons are made visible.
    # If not, the buttons are created
    showCoursesOfSubject: (subject, ops={}) ->
        showCourses = =>
            for hash,course of @sortableCourses
                if course.subject is subject
                    course.$elm.show(ops.animate)
        if @loadedSubjects[subject]
            @populateYearChartWithSubject(subject, ops)
            showCourses()
        else
            ops = dupObject(ops)
            ops.recursionDepth = (ops.recursionDepth || 0) + 1
            if ops.recursionDepth < 10
                @loadSubjectData(subject, (=> @showCoursesOfSubject(subject, ops)), ops)
            else
                ops.error() if ops.error
                console.log Error("Reached maximum recusion depth when loading #{subject}")
        return
    # hide all courses from a particular department
    # that aren't marked as required or as an elective
    hideCoursesOfSubject: (subject, ops={}) ->
        for hash,course of @sortableCourses
            if course.subject is subject and course.state.required is false and course.state.elective is false
                if course.elm
                    course.$elm.hide(ops.animate)
        return
    hideCourse: (course, ops={}) ->
        hash = BasicCourse.hashCourse(course)
        if @sortableCourses[hash]
            course = @sortableCourses[hash]
            if course.state.required is false and course.state.elective is false
                course.$elm?.hide(ops.animate)
    populateYearChartWithSubject: (subject, ops) ->
        years = {}
        for hash,data of @courseData
            # find everything of matching subject for which a button hasn't already been created
            if data.subject is subject and not @sortableCourses[hash]
                leadingNumber = data.number.charAt(0)
                years[leadingNumber] = years[leadingNumber] || []
                years[leadingNumber].push data
        for year in ['1','2','3','4']
            list = years[year] || []
            list.sort()
            container = $(".year#{year} .courses")
            for data in list
                course = @createCourseButton(data, {clickable: true, selectable: true, draggable: true, restrictions:'nonelective'})
                @sortableCourses[course] = course
                container.append(course.getButton())
                if ops.animate
                    course.$elm.hide()
                    course.$elm.show(ops.animate)

        return
    ensureDisplayedInYearChart: (course, ops={}) ->
        hash = BasicCourse.hashCourse(course)
        # this is a course that cannot be added since it doesn't exist in a subject
        if not @courseData[hash] and @loadedSubjects[course.subject]
            ops.error() if ops.error
            throw new Error("#{hash} cannot be loaded.  Does not appear to exist...")
        # if we don't have the course's data, load it and try to display the course again
        if not @courseData[hash]
            @loadSubjectData(course.subject, (=> @ensureDisplayedInYearChart(course, ops)), ops)
            return

        # if we've already been displayed in the year chart, our job is easy
        if @sortableCourses[hash]
            @updateCourseState(course, ops.state) if ops.state
            if ops.year?
                $(".year#{ops.year} .courses").append(@sortableCourses[hash].getButton())
            ops.load(@sortableCourses[hash]) if ops.load
            @sortableCourses[hash].$elm.show(ops.animate)
            return

        # A course should show up in the year specified.  If not,
        # it should clamp to year 1 or year 4
        leadingNumber = @courseData[hash].number.charAt(0)
        leadingNumber = '1' if leadingNumber < '1'
        leadingNumber = '4' if leadingNumber > '4'
        leadingNumber = ops.year if ops.year?

        course = @createCourseButton(@courseData[hash], {clickable: true, selectable: true, draggable: true, restrictions: 'nonelective'})
        @sortableCourses[course] = course
        $(".year#{leadingNumber} .courses").append(course.getButton())
        @updateCourseState(course, ops.state) if ops.state
        ops.load(course) if ops.load
        if ops.animate
            course.$elm?.hide()
            course.$elm?.show(ops.animate)

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
        @updateGraphState()
        return @graphState.toDot()
    # binds text boxes to the extra data belonging
    # to an electivesNode (e.g. description, link to more
    # info, etc.)
    bindElectivesDescription: (course) ->
        data = course.data
        $('#electives-description').val(data.description || '')
        $('#electives-url').val(data.url || '')

        descriptionChange = ->
            val = $('#electives-description').val()
            data.description = val
        urlChange = ->
            val = $('#electives-url').val()
            data.url = val

        # let's bind the old way so our new binding
        # always replaces our old
        $('#electives-description')[0].onkeyup = ->
            window.setTimeout(descriptionChange, 0)
        $('#electives-url')[0].onkeyup = ->
            window.setTimeout(urlChange, 0)



###
# Utility functions for dealing with lists of courses and their prereqs
###
CourseUtils =
    historyToDivs: (hist={}) ->
        ret = ""
        # add the divs in this order
        for term in ['fall', 'spring', 'summer']
            if hist[term]
                ret += "<div class='availability #{term}'>#{titleCaps(term)}</div>"
        return ret || "<div class='notoffered'>Hasn't been offered in the last two years</div>"

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
            throw new Error("Yikes.  We errored while pruning the prereqs (found #{prereq} for courses #{courses}!)")

        ret = {op: 'and', data: []}
        if prereq.subject
            if courses.indexOf(BasicCourse.hashCourse(prereq)) is -1
                ret.data.push prereq
        switch prereq.op
            when 'or'
                ret.op = 'or'
                for course in prereq.data
                    # our prereq data isn't completely clean.  Sometimes
                    # there are null values for strange course requirements.
                    # e.g. ECON225 has "Univ English Requirement (Y=1) 1"
                    # skip past any of these nulls
                    if not course?
                        continue
                    # if we're in an 'or' list and we've found one of our items,
                    # we're done!  Return an empty list
                    prunedBranch = PrereqUtils.prunePrereqs(course, courses)
                    if prunedBranch.data?.length == 0
                        return {op: 'and', data: []}
                    # if our branch isn't empty, we better keep it around
                    ret.data.push prunedBranch
            when 'and'
                for course in prereq.data
                    if not course?
                        continue
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
        prereqsStr = prereqsToDivs(prereq)
        if not prereqsStr
            return "<div class='noprereqs'>No prerequsites</div>"
        divs = $("<div>#{prereqsStr}</div>")
        if not manager
            return divs
        for elm in divs.find('course')
            subject = elm.getAttribute('subject')
            number = elm.getAttribute('number')
            course = manager.createCourseButton({subject:subject, number:number}, {clickable:true, insertOnClick:true, restrictions:'nonelective'})
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
        if typeof course is 'string'
            return course
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

    getTermsOffered: (currentTerm='', goBackNYears=0)->
        currentYear = parseInt(currentTerm.slice(-4,-2), 10)
        ret = {}
        for k of @data.terms_offered || {}
            # We may only want to include terms a course was offered in recent years
            if goBackNYears > 0 and currentTerm
                if parseInt(k.slice(-4,-2), 10) < currentYear - goBackNYears
                    continue
            month = k.slice(-2)
            switch month
                when '09'
                    ret['fall'] = (ret['fall'] || 0) + 1
                when '01'
                    ret['spring'] = (ret['spring'] || 0) + 1
                when '05'
                    ret['summer'] = (ret['summer'] || 0) + 1
        return ret

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
        @setTooltip(titleCaps(@data.title))
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
    setTooltip: (tip) ->
        if tip
            @$elm.attr({title: tip})
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
    # set to be 'elective' or 'nonelective' options
    # only.  setRestrictions(null) removes the restrictions
    setRestrictions: (restriction) ->
        switch restriction
            when 'elective'
                @$elm.find('input[value=elective]').button('enable')
                @$elm.find('input[value=required]').button('disable')
            when 'nonelective'
                @$elm.find('input[value=elective]').button('disable')
                @$elm.find('input[value=required]').button('enable')
            else
                @$elm.find('input[value=elective]').button('enable')
                @$elm.find('input[value=required]').button('enable')
###
# Holds a group of courses
###
class Electives
    constructor: (data) ->
        {@title, @requirements, @number} = data
        @data = data.data || {}
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
        @selectable = true
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
        @elm.course = @
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
    removeButton: (ops={detach: true}) ->
        if not @elm
            return
        for course of @courses
            @removeCourse(course, ops)
        @elm.course = null  #make sure we remove the circular ref so we can be garbage collected
        @$elm.remove()
        @elm = @$elm = null
        return
    update: (data) ->
        super(data)
        # make sure our internal courses list is up to date
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
        @selectable = true
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
        @$elm = $("""<li class='elective-editable'>
                    <button class='delete-elective' title='Delete Electives Block'></button>
                    <div class='title'>Title: <input type='text' value='#{@title}' class='ui-state-default ui-combobox-input ui-widget ui-widget-content ui-corner-all'></input></div>
                    <div class='requirements'>At least <input type='text' value='#{@requirements.units}' class='ui-state-default ui-combobox-input ui-widget ui-widget-content ui-corner-all'></input> #{@requirements.unitLabel}</div>
                    Elective Courses: <div class='dropbox courses-list'><span class='droptext'>Use the Year Chart to Add Courses</span></div>
                </li>""")
        @elm = @$elm[0]
        @$coursesDiv = @$elm.find('.courses-list')

        @$elm.find('.delete-elective').button
            icons:
                primary: 'ui-icon-trash'
            text: false
        @$elm.find('.delete-elective').click =>
            if @manager
                @manager.removeElective(@)

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
    removeButton: (ops={detach: true}) ->
        if not @elm
            return
        for course of @courses
            @removeCourse(course, ops)
        @elm.course = null  #make sure we remove the circular ref so we can be garbage collected
        @$elm.remove()
        @elm = @$elm = null
        return
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
# Class to hold the state of the current graph.  This object
# can be used for loading and saving and will preserve
# invisible and custom-added edges.
###
class Graph
    constructor: () ->
        @dirty = true   # whether we've regenerated our adjacency matrices since the last update
        @nodes = {}
        @edges = {}
        @clusters = {}
    toJSON: (stringify=true) ->
        ret =
            nodes: []
            edges: []
            clusters: []
            title: @title
            creation_date: JSON.stringify(new Date)
        for _,node of @nodes
            ret.nodes.push
                course:
                    subject: node.course.subject
                    number: node.course.number
                    state: node.course.state
                    data:
                        title: titleCaps(node.course.data?.title)
                        description: node.course.data?.description || ''
                        terms_offered: node.course.getTermsOffered?(@mostRecentTerm, 2) || {}
                year: node.year
        for _,edge of @edges
            ret.edges.push
                edge: [''+edge.edge[0], ''+edge.edge[1]]
                properties: edge.properties || {}
        for _,cluster of @clusters
            elective = cluster.cluster
            obj =
                cluster:
                    subject: elective.subject
                    number: elective.number
                    title: elective.title
                    requirements:
                        units: elective.requirements.units
                        unitLabel: elective.requirements.unitLabel
                    data: {}
                year: cluster.year
                courses: ({subject: c.subject, number: c.number} for c in cluster.courses)
            obj.cluster.data.description = elective.data.description if elective.data?.description
            obj.cluster.data.url = elective.data.url if elective.data?.url
            ret.clusters.push obj
        if stringify
            return JSON.stringify(ret)
        return ret
    fromJSON: (str, ops={}) ->
        @dirty = true
        data = JSON.parse(str)
        for node in data.nodes
            hash = BasicCourse.hashCourse(node.course)
            @nodes[hash] = node
        for edge in data.edges
            @edges[edge.edge] = edge
        for cluster in data.clusters
            hash = BasicCourse.hashCourse(cluster.cluster)
            @clusters[hash] = cluster
        @title = data.title
        return @
    clearAll: ->
        @dirty = true   # whether we've regenerated our adjacency matrices since the last update
        @nodes = {}
        @edges = {}
        @clusters = {}

    addNode: (course, ops={}) ->
        @dirty = true
        @nodes[course] =
            course: course
            year: ops.year
            term: ops.term
    removeNode: (course) ->
        @dirty = true
        delete @nodes[course]
    addEdge: (edge, ops={}) ->
        @dirty = true
        @edges[edge] =
            edge: edge
            properties: ops.properties || {}
    removeEdge: (edge) ->
        @dirty = true
        delete @edges[edge]
    # @edges and @clusters may be updated dynamically without
    # changing @edges.  This function finds any edges that refer to nodes
    # not in @nodes and removes them
    pruneOrphanedEdges: ->
        for hash,edge of @edges
            if (not @nodes[edge.edge[0]]) or (not @nodes[edge.edge[1]])
                @removeEdge(hash)
    # generates edges based on the prereqs
    # of each node.  The generated edges are compared
    # with the existing edges.  If an edge has properties.autoGenerated falsy
    # it is preserved.
    generateEdges: (ops={optimize: true}) ->
        originalEdges = @edges
        @edges = {}

        # find all edges given by prerequisites
        for _,node of @nodes
            course = node.course
            if course.prereqs?
                prereqs = (BasicCourse.hashCourse(c) for c in PrereqUtils.flattenPrereqs(course.prereqs))
                for p in prereqs
                    if @nodes[p]
                        edge = [p, BasicCourse.hashCourse(course)]
                        @edges[edge] =
                            edge: edge
                            properties: {autoGenerated: true}
        if ops.optimize
            numDeleted = 0
            {mat, list} = @_generateAdjacencyMatrix()
            optimizedMat = @_optimizeEdges(mat)
            # find everything in our original matrix that isn't
            # in our optimized matrix and delete it
            for row,i in mat
                for v,j in row when v
                    if not optimizedMat[i][j]
                        numDeleted += 1
                        edge = [list[i],list[j]]
                        delete @edges[edge]
            console.log numDeleted, 'edges deleted'

        # restore any edges that weren't autogenerated
        for hash,edge of originalEdges
            if not edge.properties?.autogenerated
                @edges[hash] = edge
        return @edges

    toDot: ->
        createAnonymousSubgraph = (parent) ->
            subgraph = graph.addSubgraph(null, parent)
            subgraph.attrs['rank'] = 'same'
            return subgraph

        #
        # Start creating the graph
        #
        graph = new DotGraph()
        # set up the root properties
        graph.rootGraph.type = 'digraph'
        graph.rootGraph.attrs['rankdir'] = 'LR'
        if @title
            graph.rootGraph.attrs['label'] = "#{@title}"
            graph.rootGraph.attrs['_title'] = "#{@title}"
            graph.rootGraph.attrs['labelloc'] = "top"
            graph.rootGraph.attrs['labelfontsize'] = 30

        #
        # Initialize each year with 3 terms
        #
        yearSubgraphs = {}
        termSubgraphs = {}
        for year in [1..4]
            yearSubgraph = graph.addSubgraph("year#{year}")
            yearSubgraphs[year] = yearSubgraph
            termSubgraphs[year] = {}
            for term in [1..3]
                termSubgraph = createAnonymousSubgraph(yearSubgraph)
                termSubgraph.attrs['rank'] = 'same'
                termSubgraphs[year][term] = termSubgraph
                # each term has an invisible node to keep the spacing
                # this node needs to be added before all others so it doesn't interfere
                marker = "YEAR#{year}TERM#{term}"
                termSubgraph.nodes[marker] = true
                graph.nodes[marker] =
                    attrs:
                        _year: year
                        _term: term
                        style: 'invis'
                        shape: 'none'
                        label: ''
                        fixedsize: 'false'
                        height: 0
                        width: 1
        # add the edges
        for _,edge of @edges
            edgeObj = {edge: edge.edge, attrs: {}}
            if edge.properties?.style is 'invis'
                edgeObj.attrs['style'] = 'invis'
            if edge.properties?.coreq
                edgeObj.attrs['arrowhead'] = 'none'
                edgeObj.attrs['weight'] = 5     # coreqs should be placed as near to eachother as possible
            graph.edges[edge.edge] = [edgeObj]
        # add the nodes
        for _,node of @nodes
            course = node.course
            hash = BasicCourse.hashCourse(course)
            graph.nodes[hash] =
                attrs:
                    _name: hash
                    _title: titleCaps(course.data?.title)
                    _year: node.year
                    shape: 'box'
                    style: 'rounded'
        # add all the rank=same subgraphs based on the number of terms are required
        for year in [1..4]
            {mat, list} = @_generateAdjacencyMatrix({filterByYear: year})
            levels = @_stratify(mat)
            for termClust,i in levels
                rankSubgraph = termSubgraphs[year][i+1]     #the term is i+1
                for index in termClust
                    course = list[index]
                    rankSubgraph.nodes[course] = true   # subgraphs just have a list of nodes, they never store node attributes
        # add all the clusters
        for _,cluster of @clusters
            {year, courses} = cluster
            elective = cluster.cluster
            # if we have no children, add ourselves as a regular node
            if courses.length is 0
                subgraph = termSubgraphs[year][1]
                hash = BasicCourse.hashCourse(elective)
                graph.nodes[hash] =
                    attrs:
                        _elective: true
                        _title: "#{elective.title} (#{elective.requirements.units} #{elective.requirements.unitLabel})"
                        _year: year
                        shape: 'box'
                        style: 'rounded,filled'
                        color: 'invis'
                        fillcolor: 'gray'
                subgraph.nodes[elective] = true
            # if we have children, we must create a new group
            else
                subgraph = graph.addSubgraph("cluster#{Math.random().toFixed(8).slice(3)}")
                subgraph.attrs =
                    style: 'rounded,filled'
                    color: 'gray'
                    label: "#{elective.title} (#{elective.requirements.units} #{elective.requirements.unitLabel})"
                    _title: "#{elective.title} (#{elective.requirements.units} #{elective.requirements.unitLabel})"
                    _electivesBlock: true

                for course in courses
                    hash = BasicCourse.hashCourse(course)
                    subgraph.nodes[hash] = true
                    graph.nodes[hash].attrs['color'] = 'white'
                    graph.nodes[hash].attrs['style'] = 'rounded,filled'
                    graph.nodes[hash].attrs['_inElectivesBlock'] = true

        # clean up any excess term markers.
        # to ensure proper spacing, an invisible node is placed in
        # each term.  We should cleanup any term that only has the
        # marker node in it, lest we have a bunch of blank columns
        # in our chart.
        prevMarker = null
        for year in [1..4]
            for term in [1..3]
                termSubgraph = termSubgraphs[year][term]
                # each term has an invisible node to keep the spacing
                # this node needs to be added before all others so it doesn't interfere
                marker = "YEAR#{year}TERM#{term}"
                if Object.keys(termSubgraph.nodes).length > 1 or term is 1
                    if prevMarker
                        edge = [prevMarker, marker]
                        graph.edges[edge] = [{edge: edge, attrs: {style: 'invis'}}]
                    prevMarker = marker
                else
                    graph.removeNode(marker)
                    graph.removeSubgraph(termSubgraph)

        # We need to size every node manually since viz.js cannot process html labels.
        for hash,node of graph.nodes
            # invisible nodes should be ignored
            if node.attrs['style']?.match(/invis/)
                node.attrs['label'] = ''
                continue
            node.attrs['height'] = 42 / 72
            labelWidth = Math.max(strWidthInEn(node.attrs['_title']), strWidthInEn(node.attrs['_name']))
            node.attrs['width'] = (labelWidth * 6.0 + 20) / 72
            node.attrs['fixedsize'] = true

        return astToStr(graph.generateAst())


    _generateAdjacencyMatrix: (ops={}) ->
        # returns 2 if coreq, 1 if truthy and 0 otherwise
        adjacencyEntry = (n) ->
            if n is 'coreq'
                return 2
            return +(!!n)
        # returns a row of the adjacency matrix corresponding to
        # the object e's keys
        createRow = (e) ->
            return (adjacencyEntry(e[n]) for n in nodeList)

        if ops.filterByYear?
            nodeList = (n for n of @nodes when @nodes[n].year == ops.filterByYear)
        else
            nodeList = (n for n of @nodes)
        # for each node, generate a list of all the out edges it has
        outEdges = {}
        for _,e of @edges
            edge = e.edge
            outEdges[edge[0]] = (outEdges[edge[0]] || {})
            outEdges[edge[0]][edge[1]] = true
            # keep track if we are a coreq edge
            if e.properties?.coreq
                outEdges[edge[0]][edge[1]] = 'coreq'
        # build the actual matrix
        ret = (createRow(outEdges[n] || {}) for n in nodeList)
        # if there are no nodes we should still return a 2-dim matrix
        if ret.length is 0
            ret.push []
        return {mat:ret, list:nodeList}
    # computes powers of the adjacency matrix to find the span of each node
    _matrixSpan: (mat) ->
        size = mat[0].length
        if size <= 1
            return mat
        iters = Math.ceil(Math.log(size)/Math.log(2))
        for i in [0...iters]
            mat = numeric.add(numeric.dot(mat, mat), mat)
        return numeric.gt(mat, 0)
    # returns a pruned adjaency matrix.  If there is more
    # than one route from a->b, only the longer one is kept
    _optimizeEdges: (mat) ->
        ret = numeric.clone(mat)
        mat_transpose = numeric.transpose(mat)
        mat_span = @_matrixSpan(mat)

        nodes = [0...mat[0].length]
        # the idea is, suppose we have a->b->d->c and a->c
        # If node=c, then we have immediate predecessors a,d, but d
        # is in the span of a, so the edge a->c is redundant since
        # there exists a longer path a->..->c
        for node in nodes
            predicessors = mat_transpose[node]
            # loops through our predicessors
            for v,i in predicessors when (v > 0 and i != node)
                span = mat_span[i]
                existsOtherRoute = false
                for v,j in span when v>0
                    if predicessors[j] > 0
                        existsOtherRoute = true
                        break
                if existsOtherRoute
                    ret[i][node] = 0
        return ret
    # returns a list of lists of nodes
    # where if a->b then a is in a lower
    # level than b. We will attempt
    # to split them into at most maxLevels number of levels based
    # on arrow direction and returns the stratification.
    # e.g. "a->b->c, d" would split into [a,d] then [b] then [c]
    #
    # coreqs arrows are first collapsed into a single node so they
    # should always end up on the same level
    _stratify: (mat, maxLevels=3, coreqsOnSameLevel=true) ->
        if mat[0].length is 0
            return []
        # puts everything of a particular rank on its own array
        unflatten = (ranks) ->
            levels = ([] for i in [0...3])
            for rank,i in ranks
                levels[rank].push i
            return levels

        stratify = (mat, maxLevels) =>
            numNodes = mat[0].length
            mat_span = @_matrixSpan(mat)

            ranks = (0 for i in [0...numNodes])
            incrementRanks = (nodes) ->
                for v,i in nodes when v > 0
                    ranks[i] += 1
            # `nodes` is a boolean list.  forwardSpan generates a boolean
            # list of all nodes reachable in one step by the ones listed in `nodes`
            forwardSpan = (nodes) ->
                ret = (false for i in [0...numNodes])
                for v,i in nodes when v > 0
                    # mat_span[i] is precisely the nodes reachable by v
                    numeric.oreq(ret, mat_span[i])
                return ret

            # iteratively bump up the level of each relevant node
            for level in [0...maxLevels-1]
                nodesOfCurrentLevel = (l == level for l in ranks)
                needUpdating = forwardSpan(nodesOfCurrentLevel)
                incrementRanks(needUpdating)

            return ranks

        if not coreqsOnSameLevel
            return unflatten(stratify(mat, maxLevels))

        # if we want coreqs on the same levels, we do the following:
        #     * identify all connected components of coreqs
        #     * pick a representative from each component
        #     * create a new adjacency matrix consisting only
        #     of representatives by collapsing coreqs
        #     to a single node (while preserving edges)
        #     * rank in the usual way
        #     * assign ranks to the non-representatives

        # pass in a mask specifying true/false for
        # whether each row/column should zeroed in the returned
        # matrix.
        zeroedSubmatrix = (mat, mask) ->
            mat = numeric.clone(mat)
            for m,i in mask
                if not m
                    numeric.muleq(mat[i], 0)
                else
                    numeric.muleq(mat[i], mask)
            return mat

        # find the connected components of coreqs so we can pick a
        # representative from each one
        coreqAdj = numeric.clone(mat)
        coreqAdj = numeric.eq(coreqAdj,2)
        coreqAdj = numeric.or(coreqAdj, numeric.transpose(coreqAdj))
        coreqAdj = @_matrixSpan(coreqAdj)

        mask = (true for _ in [0...coreqAdj[0].length])
        reps = (v for v in [0...coreqAdj[0].length])
        for row,i in coreqAdj when mask[i]
            # for each row, mask everything that appears except for ourselves.
            # This forces one representative from each connected component.
            for val,j in row when (i != j and val)
                mask[j] = false
                reps[j] = i

        oreqRow = (mat, row1, row2) ->
            numeric.oreq(mat[row1], mat[row2])
        oreqCol = (mat, col1, col2) ->
            for row in mat
                row[col1] |= row[col2]

        collapsedMat = numeric.clone(mat)
        for rep,i in reps
            # add all the outgoing arrows of anything
            # in our connected component.
            oreqRow(collapsedMat, rep, i)
            # add all the incoming arrows of anything
            # in our connected component.
            oreqCol(collapsedMat, rep, i)
        # eliminate any self loops that were necessarily introduced
        # because every rep that is part of a non-trivial component
        # points to something else in that component.
        for i in [0...collapsedMat[0].length]
            collapsedMat[i][i] = 0
        repMat = zeroedSubmatrix(collapsedMat, mask)
        repRanks = stratify(repMat, maxLevels)
        for i in [0...repRanks.length]
            repRanks[i] = repRanks[reps[i]]
        return unflatten(repRanks)


###
# Various methods of downloading data to the users compuer so they can save it.
# Initially DownloadManager.download will try to bounce off download.php,
# a server-side script that sends the data it receives back with approprate
# headers. If this fails, it will try to use the blob API to and the
# 'download' attribute of an anchor to download the file with a suggested file name.
# If this fails, a dataURI is used.
###
class DownloadManager
    DOWNLOAD_SCRIPT: 'download.php'
    constructor: (@filename, @data, @mimetype='application/octet-stream') ->
    # a null status means no checks have been performed on whether that method will work
        @downloadMethodAvailable =
            serverBased: null
            blobBased: null
            dataUriBased: null

    # run through each download method and if it works,
    # use that method to download the graph. @downloadMethodAvailable
    # starts as all null and will be set to true or false after a test has been run
    download: () =>
        if @downloadMethodAvailable.serverBased == null
            @testServerAvailability(@download)
            return
        if @downloadMethodAvailable.serverBased == true
            @downloadServerBased()
            return

        if @downloadMethodAvailable.blobBased == null
            @testBlobAvailability(@download)
            return
        if @downloadMethodAvailable.blobBased == true
            @downloadBlobBased()
            return

        if @downloadMethodAvailable.dataUriBased == null
            @testDataUriAvailability(@download)
            return
        if @downloadMethodAvailable.dataUriBased == true
            @downloadDataUriBased()
            return

    testServerAvailability: (callback = ->) =>
        $.ajax
            url: @DOWNLOAD_SCRIPT
            dataType: 'text'
            success: (data, status, response) =>
                if response.getResponseHeader('Content-Description') is 'File Transfer'
                    @downloadMethodAvailable.serverBased = true
                else
                    @downloadMethodAvailable.serverBased = false
                callback.call(this)
            error: (data, status, response) =>
                @downloadMethodAvailable.serverBased = false
                callback.call(this)

    testBlobAvailability: (callback = ->) =>
        if (window.webkitURL or window.URL) and (window.Blob or window.MozBlobBuilder or window.WebKitBlobBuilder)
            @downloadMethodAvailable.blobBased = true
        else
            @downloadMethodAvailable.blobBased = true
        callback.call(this)

    testDataUriAvailability: (callback = ->) =>
        # not sure how to check for this ...
        @downloadMethodAvailable.dataUriBased = true
        callback.call(this)

    downloadServerBased: () =>
        input1 = $('<input type="hidden"></input>').attr({name: 'filename', value: @filename})
        # encode our data in base64 so it doesn't get mangled by post (i.e., so '\n' to '\n\r' doesn't happen...)
        input2 = $('<input type="hidden"></input>').attr({name: 'data', value: btoa(@data)})
        input3 = $('<input type="hidden"></input>').attr({name: 'mimetype', value: @mimetype})
        # target=... is set to our hidden iframe so we don't change the url of our main page
        form = $('<form action="'+@DOWNLOAD_SCRIPT+'" method="post" target="downloads_iframe"></form>')
        form.append(input1).append(input2).append(input3)

        # submit the form and hope for the best!
        form.appendTo(document.body).submit().remove()

    downloadBlobBased: (errorCallback=@download) =>
        try
            # first convert everything to an arraybuffer so raw bytes in our string
            # don't get mangled
            buf = new ArrayBuffer(@data.length)
            bufView = new Uint8Array(buf)
            for i in [0...@data.length]
                bufView[i] = @data.charCodeAt(i) & 0xff

            try
                # This is the recommended method:
                blob = new Blob(buf, {type: 'application/octet-stream'})
            catch e
                # The BlobBuilder API has been deprecated in favour of Blob, but older
                # browsers don't know about the Blob constructor
                # IE10 also supports BlobBuilder, but since the `Blob` constructor
                # also works, there's no need to add `MSBlobBuilder`.
                bb = new (window.WebKitBlobBuilder || window.MozBlobBuilder)
                bb.append(buf)
                blob = bb.getBlob('application/octet-stream')

            url = (window.webkitURL || window.URL).createObjectURL(blob)

            downloadLink = $('<a></a>').attr({href: url, download: @filename})
            $(document.body).append(downloadLink)
            # trigger the file save dialog
            downloadLink[0].click()
            # clean up when we're done
            downloadLink.remove()
        catch e
            @downloadMethodAvailable.blobBased = false
            errorCallback.call(this)

    downloadDataUriBased: () =>
        document.location.href = "data:application/octet-stream;base64," + btoa(@data)

###
# utilities for client-side reading files
###
FileHandler =
    decodeDataURI: (dataURI) ->
        content = dataURI.indexOf(",")
        meta = dataURI.substr(5, content).toLowerCase()
        data = decodeURIComponent(dataURI.substr(content + 1))
        data = atob(data) if /;\s*base64\s*[;,]/.test(meta)
        data = decodeURIComponent(escape(data)) if /;\s*charset=[uU][tT][fF]-?8\s*[;,]/.test(meta)
        data

    handleFiles: (files) ->
        file = files[0]
        #document.getElementById("droplabel").innerHTML = "Processing " + file.name
        reader = new FileReader()
        reader.onprogress = FileHandler.handleReaderProgress
        reader.onloadend = FileHandler.handleReaderLoadEnd
        reader.readAsDataURL file

    handleReaderProgress: (evt) ->
        percentLoaded = (evt.loaded / evt.total) if evt.lengthComputable

    handleReaderLoadEnd: (evt) ->
        if evt.target.error
            throw new Error(evt.target.error + " Error Code: " + evt.target.error.code + " ")
            return
        data = FileHandler.decodeDataURI(evt.target.result)
        # process the data depending on the file format.  We're going
        # to do this by trial and error, assuming different formats
        try
            try
                jsonData = JSON.parse(data)
                window.courseManager.loadGraph(data)
            catch e
                parser = new DOMParser
                xmlDoc = parser.parseFromString(data, 'text/xml')
                data = decodeURIComponent(xmlDoc.querySelector('coursemapper').textContent)
                jsonData = JSON.parse(data)
                window.courseManager.loadGraph(data)
        catch e
            console.log e
            throw new Error("Not valid JSON or SVG (containing <coursemapper>JSON</coursemapper>) data")

    dragEnter: (evt) ->
        $('#dropcontainer').show()
        $('.tabs').hide()
        $('#forkme').hide()
        evt.stopPropagation()
        evt.preventDefault()
    dragExit: (evt) ->
        $('#dropcontainer').hide()
        $('#dropbox').removeClass('dropbox-hover')
        $('.tabs').show()
        $('#forkme').show()
        if evt?
            evt.stopPropagation()
            evt.preventDefault()
    dragOver: (evt,b) ->
        if not evt?
            $('#dropbox').removeClass('dropbox-hover')
            return
        $('#dropbox').addClass('dropbox-hover')
        evt.stopPropagation()
        evt.preventDefault()
    drop: (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        files = evt.dataTransfer.files
        count = files.length
        FileHandler.handleFiles files if count > 0
        # fake the exit of a drag event...
        FileHandler.dragExit()
