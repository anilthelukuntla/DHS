global class GrammarCheckController {
	@RemoteAction
    global static string sendRequest(string inputText,string leadId){
        string returnData = processSingle(inputText,leadId);
        system.debug('returnData...'+returnData);
        return returnData;
    }
    // shared generator
    private static String processSingle(String inputText,string leadId) {
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();

            input.isPreview = false;

            input.additionalConfig =
                new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName =
                'PromptTemplateGenerationsInvocable';

            Map<String, ConnectApi.WrappedValue> valueMap =
                new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue wrappedInput =
                new ConnectApi.WrappedValue();
            wrappedInput.value = inputText;

            valueMap.put('Input:inputText', wrappedInput);

            input.inputParams = valueMap;
			string promptTemplateId = system.label.Grammer_Prompt_Template_Id;
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    promptTemplateId,
                    input
                );
            if (result != null && result.generations != null && !result.generations.isEmpty()) {
                String rawText = result.generations[0].text;
				rawText = rawText.replace('```json', '').replace('```', '').trim();
				Object parsed = JSON.deserializeUntyped(rawText);
                /*Lead__c l = [select id from Lead__c where id =: leadId limit 1];
                l.Grammar_Checked__c = true;
                update l;*/
				return JSON.serialize(parsed);
                
            }
            return null;
        } catch (Exception e) {
            System.debug('GEN AI ERROR: ' + e.getMessage());
            throw e;
        }
    }
}