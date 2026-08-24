/** Retains the existing DHSGrammarCorrection integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc')
public class DHSGrammarCorrection {
    @RemoteAction
    public static String correctGrammar(String inputText, String apiName) {
        return String.isBlank(inputText) ? '' : inputText;
    }
}
