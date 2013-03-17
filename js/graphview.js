// Generated by CoffeeScript 1.4.0
var GraphManager, Mat, SVGZoomer, loadSVG, resize,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

loadSVG = function(url, callback) {
  window.xhr = new XMLHttpRequest;
  xhr.onreadystatechange = function() {
    var graph;
    if (xhr.readyState === 4) {
      graph = document.getElementById('graphview-graph');
      graph.innerHTML = xhr.responseText;
      return typeof callback === "function" ? callback(graph.childNodes[0]) : void 0;
    }
  };
  xhr.open('GET', url, true);
  xhr.setRequestHeader('Content-type', 'image/svg+xml');
  return xhr.send();
};

resize = function(svg) {
  window.zoomer = new SVGZoomer(svg);
  zoomer.zoomFit();
  document.getElementById('graphview-zoom-in').onclick = function() {
    return zoomer.zoomIn();
  };
  document.getElementById('graphview-zoom-out').onclick = function() {
    return zoomer.zoomOut();
  };
  document.getElementById('graphview-zoom-fit').onclick = function() {
    return zoomer.zoomFit();
  };
  window.manager = new GraphManager(svg);
};

/*
# Mini matrix library
*/


Mat = {
  row: function(n) {
    var i, ret, _i;
    ret = new Array(n);
    for (i = _i = 0; 0 <= n ? _i < n : _i > n; i = 0 <= n ? ++_i : --_i) {
      ret[i] = 0;
    }
    return ret;
  },
  zeros: function(rows, cols) {
    var i, ret, _i;
    ret = new Array(rows);
    for (i = _i = 0; 0 <= rows ? _i < rows : _i > rows; i = 0 <= rows ? ++_i : --_i) {
      ret[i] = Mat.row(cols);
    }
    return ret;
  },
  identity: function(rows, cols) {
    var i, ret, _i, _ref;
    ret = Mat.zeros(rows, cols);
    for (i = _i = 0, _ref = Math.min(rows, cols); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      ret[i][i] = 1;
    }
    return ret;
  },
  copy: function(mat) {
    var cols, i, ret, rows, _i;
    rows = mat.length;
    cols = mat[0].length;
    ret = new Array(rows);
    for (i = _i = 0; 0 <= rows ? _i < rows : _i > rows; i = 0 <= rows ? ++_i : --_i) {
      ret[i] = mat[i].slice();
    }
    return ret;
  },
  transpose: function(mat) {
    var cols, i, j, ret, rows, _i, _j;
    rows = mat.length;
    cols = mat[0].length;
    ret = Mat.zeros(cols, rows);
    for (i = _i = 0; 0 <= cols ? _i < cols : _i > cols; i = 0 <= cols ? ++_i : --_i) {
      for (j = _j = 0; 0 <= rows ? _j < rows : _j > rows; j = 0 <= rows ? ++_j : --_j) {
        ret[i][j] = mat[j][i];
      }
    }
    return ret;
  },
  gt: function(mat, num) {
    var cols, i, j, rows, _i, _j;
    rows = mat.length;
    cols = mat[0].length;
    for (i = _i = 0; 0 <= rows ? _i < rows : _i > rows; i = 0 <= rows ? ++_i : --_i) {
      for (j = _j = 0; 0 <= cols ? _j < cols : _j > cols; j = 0 <= cols ? ++_j : --_j) {
        mat[i][j] = (mat[i][j] > num) | 0;
      }
    }
    return mat;
  },
  sum: function(mat1, mat2) {
    var cols, i, j, ret, rows, _i, _j;
    rows = mat1.length;
    cols = mat1[0].length;
    ret = mat1;
    for (i = _i = 0; 0 <= rows ? _i < rows : _i > rows; i = 0 <= rows ? ++_i : --_i) {
      for (j = _j = 0; 0 <= cols ? _j < cols : _j > cols; j = 0 <= cols ? ++_j : --_j) {
        ret[i][j] = mat1[i][j] + mat2[i][j];
      }
    }
    return ret;
  },
  dot: function(vec1, vec2) {
    var i, ret, _i, _ref;
    ret = 0;
    for (i = _i = 0, _ref = vec1.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      ret += vec1[i] * vec2[i];
    }
    return ret;
  },
  mul: function(mat1, mat2) {
    var cols, i, j, mat2t, ret, rows, _i, _j;
    mat2t = Mat.transpose(mat2);
    rows = mat1.length;
    cols = mat2[0].length;
    ret = Mat.zeros(rows, cols);
    for (i = _i = 0; 0 <= rows ? _i < rows : _i > rows; i = 0 <= rows ? ++_i : --_i) {
      for (j = _j = 0; 0 <= cols ? _j < cols : _j > cols; j = 0 <= cols ? ++_j : --_j) {
        ret[i][j] = Mat.dot(mat1[i], mat2t[j]);
      }
    }
    return ret;
  },
  pow: function(mat, pow) {
    var a, bin, curr, i, powers, ret, _i, _j, _len, _ref;
    bin = Mat.numToBinary(pow);
    powers = new Array(bin.length);
    curr = mat;
    for (i = _i = 0, _ref = bin.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      powers[i] = curr;
      curr = Mat.mul(curr, curr);
    }
    ret = Mat.identity(mat.length, mat[0].length);
    for (i = _j = 0, _len = bin.length; _j < _len; i = ++_j) {
      a = bin[i];
      if (a) {
        ret = Mat.mul(ret, powers[i]);
      }
    }
    return ret;
  },
  powerSum: function(mat, pow) {
    var bin, curr, i, _i, _ref;
    bin = Mat.numToBinary(pow);
    curr = mat;
    for (i = _i = 0, _ref = bin.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      curr = Mat.sum(Mat.mul(curr, mat), mat);
    }
    return curr;
  },
  numToBinary: function(num) {
    var curr, i, len, ret, _i;
    if (num <= 0) {
      len = 0;
    } else {
      len = Math.floor(Math.log(num) / Math.log(2)) + 1;
    }
    ret = new Array(len);
    curr = num;
    for (i = _i = 0; 0 <= len ? _i < len : _i > len; i = 0 <= len ? ++_i : --_i) {
      ret[i] = curr & 1;
      curr = curr >> 1;
    }
    return ret;
  },
  prettyPrint: function(mat) {
    var padd3, row, rowToStr;
    padd3 = function(num) {
      return ("   " + num).slice(-3);
    };
    rowToStr = function(row) {
      var e;
      return ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = row.length; _i < _len; _i++) {
          e = row[_i];
          _results.push(padd3(e));
        }
        return _results;
      })()).join('');
    };
    return ((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = mat.length; _i < _len; _i++) {
        row = mat[_i];
        _results.push(rowToStr(row));
      }
      return _results;
    })()).join('\n');
  }
};

SVGZoomer = (function() {

  SVGZoomer.prototype.ZOOM_FACTOR = 1.2;

  SVGZoomer.prototype.PAN_TOLERANCE = 5;

  function SVGZoomer(svg) {
    var d, dims,
      _this = this;
    this.svg = svg;
    this._onMouseMove = __bind(this._onMouseMove, this);

    this._onMouseDown = __bind(this._onMouseDown, this);

    this._onMouseUp = __bind(this._onMouseUp, this);

    this.parent = this.svg.parentNode;
    this.svg.getElementById = this.svg.getElementById || function(id) {
      return _this.parent.getElementById(id);
    };
    this.svg.querySelector = this.svg.querySelector || function(srt) {
      return _this.parent.querySelector(str);
    };
    this.svg.querySelectorAll = this.svg.querySelectorAll || function(srt) {
      return _this.parent.querySelectorAll(str);
    };
    if (this.svg.getAttribute('viewBox')) {
      dims = this.svg.getAttribute('viewBox').split(/[^\w]+/);
      dims = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = dims.length; _i < _len; _i++) {
          d = dims[_i];
          _results.push(parseFloat(d));
        }
        return _results;
      })();
      this.width = dims[2] - dims[0];
      this.height = dims[3] - dims[1];
    } else {
      this.width = parseFloat(this.svg.getAttribute('width'));
      this.height = parseFloat(this.svg.getAttribute('height'));
      this.svg.setAttribute('viewBox', "0 0 " + this.width + " " + this.height);
    }
    this.currentZoomFactor = 1;
    this.aspect = this.width / this.height;
    this.zoom();
    this.buttonPressed = false;
    this.oldMousePos = [-1, -1];
    this.panning = false;
    this.totalPan = [0, 0];
    this.svg.addEventListener('mousedown', this._onMouseDown, false);
    document.body.addEventListener('mouseup', this._onMouseUp, false);
    this.svg.addEventListener('mousemove', this._onMouseMove, false);
  }

  SVGZoomer.prototype._onMouseUp = function(event) {
    this.buttonPressed = false;
    this.totalPan[0] = 0;
    this.totalPan[1] = 1;
    return this.panning = false;
  };

  SVGZoomer.prototype._onMouseDown = function(event) {
    if (event.button === 0) {
      return this.buttonPressed = true;
    }
  };

  SVGZoomer.prototype._onMouseMove = function(event) {
    var dx, dy, x, y;
    x = event.clientX;
    y = event.clientY;
    if (this.oldMousePos[0] === -1) {
      this.oldMousePos[0] = x;
      this.oldMousePos[1] = y;
    }
    dx = x - this.oldMousePos[0];
    dy = y - this.oldMousePos[1];
    if (!this.buttonPressed || (dx === 0 && dy === 0)) {
      this.oldMousePos[0] = x;
      this.oldMousePos[1] = y;
      return;
    }
    this.totalPan[0] += dx;
    this.totalPan[1] += dy;
    if ((!this.panning) && Math.abs(this.totalPan[0]) + Math.abs(this.totalPan[1]) > this.PAN_TOLERANCE) {
      this.panning = true;
      dx = this.totalPan[0];
      dy = this.totalPan[1];
    }
    if (this.panning) {
      this.parent.scrollTop -= dy;
      this.parent.scrollLeft -= dx;
    }
    this.oldMousePos[0] = x;
    this.oldMousePos[1] = y;
  };

  SVGZoomer.prototype.zoomIn = function(factor) {
    if (factor == null) {
      factor = this.ZOOM_FACTOR;
    }
    this.currentZoomFactor *= factor;
    return this.zoom();
  };

  SVGZoomer.prototype.zoomOut = function(factor) {
    if (factor == null) {
      factor = this.ZOOM_FACTOR;
    }
    this.currentZoomFactor /= factor;
    return this.zoom();
  };

  SVGZoomer.prototype.zoomFit = function() {
    var height, width, _ref;
    _ref = this.parent.getBoundingClientRect(), width = _ref.width, height = _ref.height;
    this.currentZoomFactor = width / this.width;
    return this.zoom();
  };

  SVGZoomer.prototype.zoom = function(factor) {
    var height, width;
    if (factor == null) {
      factor = this.currentZoomFactor;
    }
    width = Math.round(this.width * factor);
    height = Math.round(this.height * factor);
    this.zoomedWidth = width;
    this.zoomedHeight = height;
    this.svg.setAttribute('width', width);
    this.svg.setAttribute('height', height);
    return this.svg.setAttribute('style', "width: " + width + "; height: " + height + ";");
  };

  return SVGZoomer;

})();

GraphManager = (function() {
  var addClass, hashCourse, removeClass, sanitizeId;

  hashCourse = function(course) {
    if (typeof course === 'string') {
      return course;
    }
    return "" + course.subject + " " + course.number;
  };

  sanitizeId = function(str) {
    return ('' + str).replace(/\W+/g, '-');
  };

  addClass = function(elm, cls) {
    var oldCls;
    oldCls = elm.getAttribute('class');
    if (oldCls.split(/\s+/).indexOf(cls) >= 0) {
      return;
    }
    return elm.setAttribute('class', oldCls + ' ' + cls);
  };

  removeClass = function(elm, cls) {
    var c, newCls, oldCls;
    oldCls = elm.getAttribute('class');
    if (!oldCls.match(cls)) {
      return;
    }
    newCls = (function() {
      var _i, _len, _ref, _results;
      _ref = oldCls.split(/\s+/);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        if (c !== cls) {
          _results.push(c);
        }
      }
      return _results;
    })();
    return elm.setAttribute('class', newCls.join(' '));
  };

  function GraphManager(svg) {
    var elm, _i, _j, _len, _len1, _ref, _ref1,
      _this = this;
    this.svg = svg;
    this._onCourseClicked = __bind(this._onCourseClicked, this);

    this._onClick = __bind(this._onClick, this);

    this.svg.getElementById = this.svg.getElementById || function(id) {
      return _this.parent.getElementById(id);
    };
    this.svg.querySelector = this.svg.querySelector || function(srt) {
      return _this.parent.querySelector(str);
    };
    this.svg.querySelectorAll = this.svg.querySelectorAll || function(srt) {
      return _this.parent.querySelectorAll(str);
    };
    this.parent = this.svg.parentNode;
    _ref = this.svg.querySelectorAll('*');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      elm = _ref[_i];
      elm.setAttribute('style', null);
    }
    this.data = JSON.parse(decodeURIComponent(this.svg.querySelector('coursemapper').textContent));
    this.processData();
    console.log(this.data);
    _ref1 = this.svg.querySelectorAll('g.node');
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      elm = _ref1[_j];
      elm.addEventListener('click', this._onCourseClicked, true);
    }
  }

  GraphManager.prototype.processData = function() {
    var course, edge, elm, hash, i, j, node, numNodes, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    this.courses = {};
    this.coursesList = [];
    _ref = this.data.nodes;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      node = _ref[i];
      course = node.course;
      hash = hashCourse(course);
      this.courses[hash] = course;
      this.coursesList.push(hash);
      course.listPos = i;
      course.year = node.year;
      elm = this.svg.getElementById(sanitizeId(hash));
      if (elm) {
        course.elm = elm;
        elm.courseHash = hash;
      }
    }
    numNodes = this.coursesList.length;
    this.adjacencyMat = Mat.zeros(numNodes, numNodes);
    _ref1 = this.data.edges;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      edge = _ref1[_j];
      if ((_ref2 = edge.properties.style) != null ? _ref2.match(/invis/) : void 0) {
        continue;
      }
      i = this.courses[edge.edge[0]].listPos;
      j = this.courses[edge.edge[1]].listPos;
      this.adjacencyMat[i][j] = 1;
      if (edge.properties.coreq) {
        this.adjacencyMat[i][j] = 2;
      }
    }
    this.adjacencyMatCoreq = Mat.gt(Mat.copy(this.adjacencyMat), 1);
    this.adjacencyMatCoreq = Mat.sum(this.adjacencyMatCoreq, Mat.transpose(this.adjacencyMatCoreq));
    this.adjacencyMat = Mat.sum(this.adjacencyMat, this.adjacencyMatCoreq);
    this.span = Mat.gt(Mat.powerSum(this.adjacencyMat, this.adjacencyMat.length), 0);
    this.correqSpan = Mat.gt(Mat.powerSum(this.adjacencyMatCoreq, this.adjacencyMatCoreq.length), 0);
  };

  GraphManager.prototype.coursePrereqs = function(course) {
    var e, hash, i, index, ret, spanT, _i, _len, _ref;
    hash = hashCourse(course);
    spanT = Mat.transpose(this.span);
    index = this.courses[hash].listPos;
    ret = [];
    _ref = spanT[index];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      e = _ref[i];
      if (e) {
        ret.push(this.coursesList[i]);
      }
    }
    return ret;
  };

  GraphManager.prototype._onClick = function(event) {
    var _ref;
    if (((_ref = event.target.getAttribute('class')) != null ? _ref.match(/course/) : void 0) || true) {
      event.currentTarget = event.target;
      return this._onCourseClicked(event);
    }
  };

  GraphManager.prototype._onCourseClicked = function(event) {
    var elm;
    elm = event.currentTarget;
    console.log(elm.courseHash, elm);
    return this.selectCourse(elm.courseHash);
  };

  GraphManager.prototype.selectCourse = function(course) {
    var c, elm, hash, id, prereq, prereqs, _, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2, _ref3;
    hash = hashCourse(course);
    prereqs = this.coursePrereqs(hash);
    _ref = this.courses;
    for (_ in _ref) {
      c = _ref[_];
      removeClass(c.elm, 'highlight');
    }
    for (_i = 0, _len = prereqs.length; _i < _len; _i++) {
      prereq = prereqs[_i];
      addClass(this.courses[prereq].elm, 'highlight');
    }
    addClass(this.courses[hash].elm, 'highlight');
    _ref1 = this.svg.querySelectorAll('g.edge');
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      elm = _ref1[_j];
      removeClass(elm, 'highlight');
    }
    _ref2 = prereqs.concat([hash]);
    for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
      prereq = _ref2[_k];
      id = sanitizeId(prereq);
      _ref3 = this.svg.querySelectorAll("[target=" + id + "]");
      for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
        elm = _ref3[_l];
        addClass(elm, 'highlight');
      }
    }
    this.courseRequirementsSummary(course);
    return this.createCourseSummary(course);
  };

  GraphManager.prototype.courseRequirementsSummary = function(course) {
    var c, hash, prereq, prereqs, year, years, yearsTitles, _i, _j, _k, _l, _len, _len1, _ref;
    hash = hashCourse(course);
    prereqs = this.coursePrereqs(hash);
    years = {};
    yearsTitles = {};
    for (year = _i = 1; _i <= 4; year = ++_i) {
      years[year] = [];
      yearsTitles[year] = [];
    }
    for (_j = 0, _len = prereqs.length; _j < _len; _j++) {
      prereq = prereqs[_j];
      c = this.courses[prereq];
      years[c.year].push(c);
    }
    for (year = _k = 1; _k <= 4; year = ++_k) {
      _ref = years[year];
      for (_l = 0, _len1 = _ref.length; _l < _len1; _l++) {
        c = _ref[_l];
        yearsTitles[year].push("" + (hashCourse(c)) + " (" + c.title + ")");
      }
      yearsTitles[year].sort();
    }
    return console.log(yearsTitles[1], yearsTitles[2], yearsTitles[3], yearsTitles[4]);
  };

  GraphManager.prototype.createCourseSummary = function(course) {
    var elm, hash, infoArea, term, _i, _len, _ref, _ref1, _ref2, _ref3;
    hash = hashCourse(course);
    course = this.courses[course];
    infoArea = document.querySelector('#graphview-courseinfo');
    if ((_ref = infoArea.querySelector('.name')) != null) {
      _ref.textContent = hash;
    }
    if ((_ref1 = infoArea.querySelector('.title')) != null) {
      _ref1.textContent = course.data.title;
    }
    _ref2 = ['fall', 'spring', 'summer'];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      term = _ref2[_i];
      elm = infoArea.querySelector("." + term);
      if (course.data.terms_offered[term]) {
        removeClass(elm, "hidden");
      } else {
        addClass(elm, "hidden");
      }
    }
    return (_ref3 = infoArea.querySelector('.description')) != null ? _ref3.textContent = course.data.description : void 0;
  };

  return GraphManager;

})();

window.onload = function() {
  return loadSVG('testdata/test.svg', resize);
};