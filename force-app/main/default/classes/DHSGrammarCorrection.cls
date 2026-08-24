/**
 * @description Retains the existing DHSGrammarCorrection integration and application behavior.
 */

public class DHSGrammarCorrection {
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param inputText Method parameter.
     * @param apiName Method parameter.
     * @return The requested result.
     */
    public static String correctGrammar(String inputText, String apiName) {
        return String.isBlank(inputText) ? '' : inputText;
    }
}
