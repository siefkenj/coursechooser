###
    Copyright 2013,2014 Jason Siefken

    This file is part of CourseChooser.

    CourseChooser is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    CourseChooser is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with CourseChooser.  If not, see <http://www.gnu.org/licenses/>.
###

###
# Objects for dealing with the Graphviz dot/xdot format.
# After obtaining an ast using DotParser.parser(source),
# you may find the following useful:
#
# astToStr: Turn an ast back into a string
#
# new DotGraph(ast): Get a dotgraph object.  Calling .walk on this
#   object will walk the ast and populate the .notes, .edges, and .graphs
#   properties.
#
# new XDotGraph(ast): Subclass of DotGraph.  Calling .walk will populate
#   .nodes, .edges, and .graphs and will parse any of the known attributes
#   to javascript objects and convert their values to pixels if necessary.
####

astToStr = (ast, indentLevel=0, indentChar='\t') ->
    ### enclose a string in quotes if it contains any non-letters or if it is a keyword
    if the value == null, return double quotes ###
    escape = (s) ->
        if not s?
            return "\"\""
        if /^[a-zA-Z0-9]+$/.test(s) and not /^(graph|digraph|subgraph|node|edge|strict)$/.test(s)
            return s
        else
            return "\"#{(''+s).replace(/"/g, '\\"')}\""
    attrListToStr = (l) ->
        if not l or l.length is 0
            return ""

        attrStrings = []
        for e in l
            s = e.id + "="
            if e.eq?.html
                s += "<#{e.eq.value}>"
            else
                s += escape(e.eq)
            attrStrings.push s
        return "[#{attrStrings.join(", ")}]"

    ret = ''
    indentStr = new Array(indentLevel + 1).join(indentChar)

    if ast instanceof Array
        ret = (astToStr(n, indentLevel) for n in ast).join('\n')

    switch ast.type
        when 'digraph', 'graph', 'subgraph'
            if ast.strict
                ret += indentStr + " strict " + ast.type
            else
                ret += indentStr + ast.type
            ret += " #{ast.id}" if ast.id
            ret += " {"
            if ast.children.length is 0
                ret += " }\n"
            else
                ret += "\n"
                ret += astToStr(ast.children, indentLevel + 1)
                ret += "\n" + indentStr + "}"
        when 'attr_stmt'
            ret += indentStr + ast.target
            attrs = attrListToStr(ast.attr_list)
            if attrs
                ret += " " + attrs
        when 'node_stmt'
            ret += indentStr + escape(ast.node_id.id)
            ret += ":#{escape(ast.node_id.port.id)}" if ast.node_id.port
            ret += ":#{ast.node_id.port.compass_pt}" if ast.node_id.port?.compass_pt
            attrs = attrListToStr(ast.attr_list)
            if attrs
                ret += " " + attrs
        when 'edge_stmt'
            ret += indentStr + (astToStr(n, 0) for n in ast.edge_list).join(' -> ')
            attrs = attrListToStr(ast.attr_list)
            if attrs
                ret += " " + attrs
        when 'node_id'
            ret += indentStr + escape(ast.id)
    return ret

###
# Takes in an AST of the dot/xdot file format
# and produces a graph object where nodes/edges/subgraphs
# may be queried for attributes
###
class DotGraph
    ###
    # returns an 8 digit random string that can be used
    # to give anonymous graphs unique ids.
    ###
    giveRandomKey = ->
        return Math.random().toFixed(8).slice(2)
    ### adds any attributes of obj2 that are missing from obj1 to obj1 ###
    mergeLeftNoOverried = (obj1, obj2) ->
        for k,v of obj2
            if not obj1[k]?
                obj1[k] = v
        return obj1
    ### adds every attribute from obj2 to obj1 overriding ones that already exist in obj1 ###
    mergeLeftOverried = (obj1, obj2) ->
        for k,v of obj2
            obj1[k] = v
        return obj1
    ### shallow copy an object ###
    copy = (obj) ->
        ret = {}
        for k,v of obj
            ret[k]=v
        return ret
    ### copy an object two levels deep ###
    doubleCopy = (obj) ->
        ret = {}
        for k,v of obj
            ret[k]=copy(v)
        return ret
    ### takes an attr_list from a graphviz dot ast and turns it into a regular object ###
    attrListToObj = (list) ->
        ret = {}
        for attr in list
            ret[attr.id] = attr.eq
        return ret
    ###
    # Light object to hold nodes and attributes of subgraphs.
    # This is really just a container and doesn't have any processing capabilities
    ###
    class DotSubgraph
        constructor: (@id, @type='subgraph', @parent=null) ->
            if not @id
                @id=giveRandomKey()
                @autogeneratedId = true
            @nodes = {}
            @attrs = {}
            @graphs = {}
        toString: ->
            return @id

    ### keep the prototype accessible from the outside world ###
    'DotSubgraph': DotSubgraph

    ###***************************************
    # Here is where the DotGraph methods start
    ###
    constructor: (@ast) ->
        @nodes = {}
        @edges = {}
        @graphs = {}
        @rootGraph = new DotSubgraph()
    ### walks the current ast and populates @nodes, @edges, and @graphs  ###
    walk: (ast=@ast) ->
        walk = (tree, state={node:{}, edge:{}, graph:{}}, currentParentGraph) =>
            if tree instanceof Array
                for elm in tree
                    walk(elm, state, currentParentGraph)
            switch tree.type
                when 'graph', 'digraph', 'subgraph'
                    oldParentGraph = currentParentGraph
                    currentParentGraph = new DotSubgraph(tree.id || null, tree.type, currentParentGraph)
                    ###
                    # when a subgraph of the same name as an already defined subgraph is mentioned,
                    # it is considered an extension of the original definition--i.e., it doesn't
                    # override the previous definition, so just continue on as if nothing ever happened
                    ###
                    if @graphs[currentParentGraph]?
                        currentParentGraph = @graphs[currentParentGraph]
                    if oldParentGraph
                        ### every graph should know all its child graphs ###
                        oldParentGraph.graphs[currentParentGraph] = currentParentGraph
                    @graphs[currentParentGraph] = currentParentGraph
                    if tree.type in ['graph', 'digraph']
                        @rootGraph = currentParentGraph
                        @rootGraph.strict = tree.strict
                    ###
                    # when walking a subgraph, we have a new state that inherits
                    # anything lying around from the old state
                    ###
                    state = doubleCopy(state)
                    walk(tree.children, state, currentParentGraph)
                when 'node_stmt'
                    id = tree.node_id.id
                    @nodes[id] = @nodes[id] || {attrs: {}}
                    ###
                    # any attributes that are specified directly with this node override
                    # the attributes previously specified for a node
                    ###
                    mergeLeftOverried(@nodes[id].attrs, attrListToObj(tree.attr_list))
                    ###
                    # the global node attributes don't overried specified attributes
                    ###
                    mergeLeftNoOverried(@nodes[id].attrs, state.node)

                    ###
                    # let's also make sure that we keep track of which subgraph
                    # has this node as a parent; we don't need to store the attr informatation
                    # though, just the nodes existance
                    ###
                    currentParentGraph.nodes[id] = true
                when 'attr_stmt'
                    ###
                    # when we set a node, edge, or graph attribute using "node [attrs]"
                    # syntax, it should affect everything, globally, from here on out,
                    # so we really do want to update by ref
                    ###
                    mergeLeftOverried(state[tree.target], attrListToObj(tree.attr_list))
                when 'edge_stmt'
                    ###
                    # first make sure all the nodes are added
                    ###
                    for node in tree.edge_list
                        if node.type is 'node_id'
                            walk({type: 'node_stmt', node_id: node, attr_list: []}, state, currentParentGraph)
                        else if node.type is 'subgraph'
                            walk(node, state, currentParentGraph)
                    ###
                    # now let's build up our edges
                    # TODO: this doesn't actually get all the nodes we're supposed to point to...if
                    # you define a subgraph twice with the same name, it needs to be combined before
                    # computing it's child nodes.  e.g. "x->subgraph a {y}; subgraph a {z}"
                    # should produce edges x->y and x->z.  Not sure of an easy fix atm...
                    ###
                    heads = getAllNodes(tree.edge_list[0])
                    for node in tree.edge_list.slice(1)
                        tails = getAllNodes(node)
                        for h in heads
                            for t in tails
                                edge = [h,t]
                                attrs = mergeLeftNoOverried(attrListToObj(tree.attr_list), state.edge)
                                @edges[edge] = @edges[edge] || []
                                @edges[edge].push {edge: edge, attrs: attrs}
                        heads = tails
            ###
            # any attributes that were set to our graph state nomatter where
            # in the AST should be applied to the current parent.  currentParentGraph
            # is reassigned every time we pass to a subgraph.
            ###
            currentParentGraph.attrs = state.graph
            return

        ###
        # walks a tree and returns a list of all nodes, disregarding
        # all other elements and attributes
        ###
        getAllNodes = (tree) ->
            ret = []
            if tree instanceof Array
                for n in tree
                    ret = ret.concat(getAllNodes(n))
                return ret
            switch tree.type
                when 'node_id'
                    ret.push tree.id
                when 'node_stmt'
                    ret.push tree.node_id.id
                when 'edge_stmt'
                    ret = ret.concat(getAllNodes(tree.edge_list))
                when 'graph','digraph','subgraph'
                    ret = ret.concat(getAllNodes(tree.children))
            return ret
        walk(ast)
        @id = @rootGraph.id
        @type = @rootGraph.type
        @strict = @rootGraph.strict
        return @

    generateAst: ->
        genAttrsAst = (attrs) ->
            if not attrs or not attrs instanceof Object
                return null
            ret = []
            for k,v of attrs
                ret.push
                    type: 'attr'
                    id: k
                    eq: v
            return ret
        genEdgesAst = (edge) ->
            ret =
                type: 'edge_stmt'
                edge_list: [{type: 'node_id', id: edge.edge[0]}, {type: 'node_id', id: edge.edge[1]}]
            attrList = genAttrsAst(edge.attrs)
            if attrList
                ret.attr_list = attrList
            return ret
        genNodeAst = (id, attrs, html) ->
            ret =
                type: 'node_stmt'
                node_id:
                    type: 'node_id'
                    id: id
            attrList = genAttrsAst(attrs.attrs)
            if attrList
                ret.attr_list = attrList
            return ret
        genSubgraphAst = (graph) ->
            ret =
                type: graph.type
                id: if graph.autogeneratedId then null else graph.id
                children: []
            ###
            # we need to list all clusters first, then other subgraphs
            # this way clusters take priority when a cluster's children
            # belong to more than one rankset
            ###
            unaddedSubgraphs = []
            for k,v of graph.graphs
                if k.slice(0,7) is 'cluster'
                    ret.children.push genSubgraphAst(v)
                else
                    unaddedSubgraphs.push v
            for v in unaddedSubgraphs
                ret.children.push genSubgraphAst(v)

            for k,v of graph.nodes
                ret.children.push genNodeAst(k,v)
            for k,v of graph.edges
                ret.children.push genEdgesAst(v)
            if Object.keys(graph.attrs).length > 0
                ret.children.push
                    type: 'attr_stmt'
                    target: 'graph'
                    attr_list: genAttrsAst(graph.attrs)
            return ret

        root = genSubgraphAst(@rootGraph)
        root.strict = @strict if @strict
        ###
        # append all the subgraphs fist, then the nodes, then the edges, then the attributes
        ###
        root.children = root.children || []
        for k,v of @nodes
            root.children.push genNodeAst(k,v)
        for k,v of @edges
            ###
            # each element of @edges is a list of edges, so add each of them
            ###
            for e in v
                root.children.push genEdgesAst(e)

        return root

    ### adds a subgraph whose parent is @rootGraph ###
    addSubgraph: (id, parent=@rootGraph) ->
        subgraph = new DotSubgraph(id)
        subgraph.parent = parent
        @graphs[subgraph] = subgraph
        parent.graphs[subgraph] = subgraph
        return subgraph
    removeNode: (id) ->
        delete @nodes[id] if @nodes[id]
        for _,graph of @graphs
            delete graph.nodes[id] if graph.nodes[id]
        return
    removeEdge: (e) ->
        delete @edges[e] if @edges[e]
        return
    removeSubgraph: (id) ->
        if @graphs[id]
            for child of @graphs[id].graphs
                delete @graphs[child] if @graphs[child]
            for _,graph of @graphs
                delete graph.graphs[id] if graph.graphs[id]
            delete @graphs[id]
        

###
# Extension of the DotGraph object that will parse node/edge/graph
# attributes like pos, width, height, etc. into the appropriate javascript types.
#
# All attributes are normalized to pixels for easier drawing.
###
class XDotGraph extends DotGraph
    toFloatList = (list) ->
        if typeof list is 'string'
            list = list.split(/[, ]/)
        return (parseFloat(v) for v in list)
    # negate the y coordinates in a list (i.e, ever second coord)
    negateYs = (list) ->
        ret = []
        for l,i in list
            if i % 2 == 0
                ret.push l
            else
                ret.push -l
        return ret
    ###
    # an object with an appropriate toString function
    # so we can convert our graphs back to text form.
    ###
    class Edge
        constructor: (val, NEGATE_Y_COORD=true, hasArrowhead=true) ->
            @type = 'edge'
            @controlPoints = []
            @arrow = null
            val = toFloatList(val)
            if hasArrowhead
                ### arrow pos are of the form "'e',arrowTargetx,arrowTargety startx,starty  <triplets of bzCurve xy-coords>, " ###
                
                ### get rid of 'e' ###
                val.shift()
                ### arrowTargets ###
                arrowTarget = val.splice(0,2)
                ### origin ###
                @origin = if NEGATE_Y_COORD then negateYs(val.splice(0,2)) else val.splice(0,2)

                controlPoints = []
                i = 0
                while i + 6 <= val.length
                    controlPoints.push if NEGATE_Y_COORD then negateYs(val.slice(i,i+6)) else val.slice(i,i+6)
                    i += 6
                @controlPoints = controlPoints
                @arrow = if NEGATE_Y_COORD then negateYs(val.slice(-2).concat(arrowTarget)) else val.slice(-2).concat(arrowTarget)
            else
                @origin = if NEGATE_Y_COORD then negateYs(val.splice(0,2)) else val.splice(0,2)

                controlPoints = []
                i = 0
                while i + 6 <= val.length
                    controlPoints.push if NEGATE_Y_COORD then negateYs(val.slice(i,i+6)) else val.slice(i,i+6)
                    i += 6
                @controlPoints = controlPoints
                @arrow = if NEGATE_Y_COORD then negateYs(val) else val
                
        toString: ->
            points = [@origin[0], @origin[1]]
            for l in @controlPoints
                points = points.concat l
            points = points.concat @arrow.slice(-2)

            return "e,#{(points[i]+','+points[i+1] for i in [0...points.length] by 2).join(' ')}"
    ### It seems like this is the value that works even though the docs say 96.... ###
    dpi: 72
    ### if you're drawing in a conventional environment like canvas or svg, you expect the positve y axis to point down ###
    NEGATE_Y_COORD: false
    walk: ->
        super()
        ### pre-process all edge and node attrs ###
        processAttrs = (graph) =>
            if not graph?
                return
            for h,n of (graph?.nodes || {})
                for attr,val of (n?.attrs || {})
                    n.attrs[attr] = @parseAttr(attr, val)
            for h,e of (graph?.edges || {})
                for edge in e
                    for attr,val of (edge?.attrs || {})
                        edge.attrs[attr] = @parseAttr(attr, val)
            for attr,val of (graph?.attrs || {})
                graph.attrs[attr] = @parseAttr(attr, val)

            for h,g of (graph?.graphs || {})
                processAttrs(g)
            return
        processAttrs(@)
        return

    ###
    # recognizes keyword attrs like pos, height, etc.
    # and will parse their arguments and return the correct type
    # accordingly.  Does nothing if attr is not recognized
    ###
    parseAttr: (attr, val) ->
        if not val
            return null
        ### if we aren't a string, we've already been parsed, and there's no need to parse again ###
        if not (typeof val == 'string')
            return val
        switch attr
            when 'width','height'
                return parseFloat(val) * @dpi
            when 'bb','lp'
                val = toFloatList(val)
                if @NEGATE_Y_COORD
                    val = negateYs(val)
                    ### if we're a bounding box, we need to switch around our coords, 'cause our lower left and upper right are upsidedown ###
                    if val.length > 2
                        tmp = val[1]
                        val[1] = val[3]
                        val[3] = tmp
                return val
            when 'pos'
                ### could be x,y-coords for a node pos, or a list for an arrow pos ###
                if val.charAt(0) is 'e'
                    return new Edge(val, @NEGATE_Y_COORD)
                else
                    ###XXX heuristic: if we have more than 2 values, we assume that we're an edge that doesn't have an arrowhead ###
                    if val.match(/,/g)?.length > 1
                        return new Edge(val, @NEGATE_Y_COORD, false)
                    else
                        return if @NEGATE_Y_COORD then negateYs(toFloatList(val)) else toFloatList(val)
        return val
