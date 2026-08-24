/**
 * @description Provides this DHS API member.
 * DHSMultiselectController synchronizes the values of the hidden elements to the
 * SelectOption lists.
 */
@SuppressWarnings('PMD.UnusedMethod')
public with sharing class DHSMultiselectController {
    /**
     * @description Options displayed in the left selection list.
     */
    public SelectOption[] leftOptions { get; set; }
    /**
     * @description Options displayed in the right selection list.
     */
    public SelectOption[] rightOptions { get; set; }
    
    // Parse &-separated values and labels from value and 
    // put them in option
    /**
     * @description Provides this DHS API member.
     * Populates an option list from URL-encoded value and label pairs.
 * @param options Option list to populate.
 * @param value Encoded value and label pairs.
     */
    private void setOptions(SelectOption[] options, String value) {
        options.clear();
        String[] parts = value.split('&');
        for (Integer i=0; i<parts.size()/2; i++) {
            options.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
              EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        }
    }
    
    // Backing for hidden text field containing the options from the
    // left list
    /**
     * @description Encoded backing value for the left option list.
     */
    public String leftOptionsHidden { get; set {
           leftOptionsHidden = value;
           setOptions(leftOptions, value);
        }
    }
    
    // Backing for hidden text field containing the options from the
    // right list
    /**
     * @description Encoded backing value for the right option list.
     */
    public String rightOptionsHidden { get; set {
           rightOptionsHidden = value;
           setOptions(rightOptions, value);
        }
    }
}
