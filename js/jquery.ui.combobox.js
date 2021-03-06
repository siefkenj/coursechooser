/*
 * Code taken from jquery autocomplete widget example
 * http://jqueryui.com/autocomplete/#combobox
 */
(function( $ ) {
    "use strict";
    function split( val ) {
        return val.split( /,\s*/ );
    }
    function extractLast( term ) {
        return split( term ).pop();
    }

    $.widget( "ui.combobox", {
        _create: function() {
            var input,
                errorBox,
                textAtSelectionTime = '',
                that = this,
                select = this.element.hide(),
                selected = select.children( ":selected" ),
                value = selected.val() ? selected.text() : "",
                wrapper = this.wrapper = $( "<span>" )
                    .addClass( "ui-combobox" )
                    .insertAfter( select ),
                // Make a hash of all the values in the option box.
                // We assume that these values don't ever change once the widgit is
                // initialized
                selectValues = [];
                select.children( "option" ).each(function() {
                    selectValues.push($( this ).text());
                });


            function removeIfInvalid(element) {
                var value = $( element ).val(),
                    matcher = new RegExp( "^" + $.ui.autocomplete.escapeRegex( value ) + "$", "i" ),
                    valid = false;
                // see if value matches anything in our list
                for (var i=0, len=selectValues.length; i< len; i++) {
                    if (selectValues[i].match(matcher)) {
                        valid = true;
                        break;
                    }
                }
                if ( !valid ) {
                    // remove invalid value, as it didn't match anything
                    elm = $( element );
                    oldTitle = elm.attr('title');
                        elm
                        .val( "" )
                        .attr( "title", value + " didn't match any item" )
                        .tooltip( "open" );
                    select.val( "" );
                    setTimeout(function() {
                        input.tooltip( "close" ).attr( "title", oldTitle );
                    }, 2500 );
                    input.data( "autocomplete" ).term = "";
                    return false;
                }
            }
            
            errorBox = this.errorBox = $( "<span id=\""+select.attr('id')+"-errorbox\" title=\"x\"></span>" )
                    .tooltip({tooltipClass: "ui-state-highlight"})
                    .appendTo( wrapper );

            input = this.input = $( "<input>" )
                .appendTo( wrapper )
                .val( value )
                .attr( "title", select.attr('title') )
                .addClass( "ui-state-default ui-combobox-input" )
                .autocomplete({
                    delay: 0,
                    minLength: 0,
                    source: function( request, response ) {
                        request.term = extractLast(request.term);
                        var matcher = new RegExp( $.ui.autocomplete.escapeRegex(request.term), "i" );
                        response( select.children( "option" ).map(function() {
                            var text = $( this ).text();
                            if ( this.value && ( !request.term || matcher.test(text) ) )
                                return {
                                    label: text.replace(
                                        new RegExp(
                                            "(?![^&;]+;)(?!<[^<>]*)(" +
                                            $.ui.autocomplete.escapeRegex(request.term) +
                                            ")(?![^<>]*>)(?![^&;]+;)", "gi"
                                        ), "<strong>$1</strong>" ),
                                    value: text,
                                    option: this
                                };
                        }) );
                    },
                    focus: function() {
                        // prevent autocomplete from subbing in the completed
                        // text.  We want to do it!
                        return false;
                    },
                    select: function( event, ui ) {
                        var terms = split(this.value);
                        terms.pop();
                        terms.push(ui.item.value);
                        terms.push('');
                        this.value = terms.join(', ')
                        
                        // make the original select box's selected value change
                        // to reflect what we've just added
                        ui.item.option.selected = true;
                        that._trigger( "selected", event, {
                            item: ui.item.option
                        });
                        
                        textAtSelectionTime = input.val();
                        return false;
                    },
                    change: function( event, ui ) {
                        /*if ( !ui.item )
                            return removeIfInvalid( this );
                        */
                    }
                })
                .keyup(function(event) {
                    // we need the timeout to make sure keyup happens after
                    // the select event.
                    window.setTimeout(function(){
                        if (event.keyCode == 13) {
                            var val = input.val();
                            // when we press enter, we check to see if our text is different
                            // from what it was when the last selection event occurred.
                            // If it is, we assume it's an authentic enter.
                            if (val !== '' && textAtSelectionTime !== val) {
                                var data = input.data( "autocomplete" );
                                if (typeof data._activateCallback === "function") {
                                    data._activateCallback(event);
                                }
                            }
                            // if we press enter twice, the text may not change, but
                            // we really intend to trigger an enter event
                            textAtSelectionTime = '';
                        }
                    },0)
                })
                .addClass( "ui-widget ui-widget-content ui-corner-left" );

            input.data( "autocomplete" )._renderItem = function( ul, item ) {
                return $( "<li>" )
                    .data( "item.autocomplete", item )
                    .append( "<a>" + item.label + "</a>" )
                    .appendTo( ul );
            };

            $( "<a>" )
                .attr( "tabIndex", -1 )
                .attr( "title", "Show All Items" )
                //.tooltip()
                .appendTo( wrapper )
                .button({
                    icons: {
                        primary: "ui-icon-triangle-1-s"
                    },
                    text: false
                })
                .removeClass( "ui-corner-all" )
                .addClass( "ui-corner-right ui-combobox-toggle" )
                .click(function() {
                    // close if already visible
                    if ( input.autocomplete( "widget" ).is( ":visible" ) ) {
                        input.autocomplete( "close" );
                        removeIfInvalid( input );
                        return;
                    }

                    // work around a bug (likely same cause as #5265)
                    $( this ).blur();

                    // pass empty string as value to search for, displaying all results
                    input.autocomplete( "search", "" );
                    input.focus();
                });

                /*input
                    .tooltip({
                        position: {
                            of: this.button
                        },
                        tooltipClass: "ui-state-highlight"
                    });*/
        },

        activate: function(callback) {
            var self = this;
            // wrap the callback to make sure the autocomplete popup is
            // always closed after an actiate event
            this.input.data( "autocomplete" )._activateCallback = function(event) {
                if ( typeof callback === 'function' ) {
                    callback(event);
                }
                // close if already visible
                if ( self.input.autocomplete( "widget" ).is( ":visible" ) ) {
                    self.input.autocomplete( "close" );
                }
            }

            return this;
        },

        value: function(str) {
            if (str == null) {
                return this.input.val();
            } else {
                this.input.val(str);
            }
            return this;
        },

        destroy: function() {
            this.wrapper.remove();
            this.element.show();
            $.Widget.prototype.destroy.call( this );
        },
        
        showError: function(msg) {
            var self = this;
            if (this.timeout) {
                window.clearTimeout(this.timeout);
            }
            this.errorBox.tooltip({content: msg}).tooltip('open');
            this.timeout = window.setTimeout(function(){ self.errorBox.tooltip('close'); }, 3500);
            return this;
        }
    });
})( jQuery );
