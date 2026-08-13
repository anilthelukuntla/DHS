/** JavaScript Remoting endpoint for PPF grammar-check requests. */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class GrammarCheckController {
    /**
     * Returns the org-compatible grammar-check response used by the page.
     * The typed Einstein API is unavailable in this Salesforce org, so the
     * existing input is returned without modification and with a clear status.
     * @param inputText Text submitted for review.
     * @param apiName API name of the originating field.
     * @return A serialized response, or an empty string for blank input.
     */
    @RemoteAction
    global static String sendRequest(String inputText, String apiName) {
        if (String.isBlank(inputText)) {
            return '';
        }
        return JSON.serialize(new Map<String, Object>{
            'apiName' => apiName,
            'text' => inputText,
            'message' => 'Grammar check is unavailable in this org.'
        });
    }
}