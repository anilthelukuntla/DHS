/*
    jQuery Autocomplete
    Library based on Jitendra Zaa's autocomplete for Salesforce lookup fields

*/
$ac = jQuery.noConflict();

function getLoadingImage()
{
    var loadImagURL = "{!URLFOR($Resource.AutoComplete, 'BigLoad.gif')}";
    var retStr = ['<img src="', loadImagURL ,'" title="loading..." alt="loading..." class="middleAlign" />'];
    return retStr.join("");
}

var sourcePage = '/apex/AC_JSON?core.apexpages.devmode.url=0';

 $ac(function() {
        var txtVal =  $ac('[id$="{!for}"]');
        //This method returns the last character of String
        function extractLast(term) {
            return term.substr(term.length - 1);
        }

        $ac('[id$="{!for}"]').autocomplete({
            source: function( request, response ) {

                //Abort Ajax
                var $this = $ac(this);
                var $element = $ac(this.element);
                var jqXHR = $element.data('jqXHR');
                if(jqXHR)
                    jqXHR.abort();

                $ac('[id$="{!for}"]').addClass('ui-autocomplete-loading');
                $element.data('jqXHR',$ac.ajax({
                    url: sourcePage+'&q='+txtVal.val()+'&obj={!SObject}&label={!Label}&value={!Value}&detail={!Details}',
                    dataType: "json",
                    data: {
                    },
                    success: function( data ) {
                        response( $ac.map( data , function( item ) {
                            return {
                                label: '<a>'+
                                item.label+"<br />"+
                                '<span style="font-size:0.8em;font-style:italic">'
                                +item.detail+
                                "</span></a>",
                                value: item.label,
                                id: item.value
                            }
                        }));
                    },
                    complete: function() {

                        //This method is called either request completed or not
                        $this.removeData('jqXHR');

                        //remove the class responsible for loading image
                        $ac('[id$="{!for}"]').removeClass('ui-autocomplete-loading');
                    }
                })
                );
            },

            search: function() {
                //If String contains at least 2 characters
                if (this.value.length >= 2)
                {
                    $ac('[id$="{!for}"]').autocomplete('option', 'delay', 100);
                    return true;
                }
                return false;
            },
            focus: function() {
                // prevent value inserted on focus
                return false;
            },
            select: function(event, ui) {
                console.log('select');
                var selectedObj = ui.item.label;
                $('[id$="myHiddenObjectId"]').val(ui.item.id);
                return true;
            }
        }).data("ui-autocomplete")._renderItem = autoCompleteRender;

    });

function autoCompleteRender(ul, item) {
    return $ac("<li></li>").data("item.autocomplete", item).append(item.label).appendTo(ul);
}