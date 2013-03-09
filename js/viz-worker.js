/* webworker wrapper around viz.js */
importScripts('viz-2.26.3.js');
self.postMessage({type: 'status', message: 'viz-loaded'});

self.onmessage = function(event) {
    var dotCode = event.data;
    var xdotCode = Viz(dotCode, 'xdot');
    xdotCode = xdotCode.slice(xdotCode.indexOf('digraph {'))
    self.postMessage({type: 'graph', message: xdotCode});
}
