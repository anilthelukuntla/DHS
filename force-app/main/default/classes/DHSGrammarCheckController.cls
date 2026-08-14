/** JavaScript Remoting endpoint for DHS grammar-check requests. */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DHSGrammarCheckController {
    /**
     * Builds the safe grammar-check fallback response used by the page.
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