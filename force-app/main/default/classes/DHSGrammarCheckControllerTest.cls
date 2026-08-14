@isTest
/** Exercises the existing DHSGrammarCheckController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.AvoidGlobalModifier, PMD.ApexDoc, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodNamingConventions')
global class DHSGrammarCheckControllerTest {

    // Mock class for ConnectApi
    global class EinsteinLLMMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            // Mocked JSON response similar to LLM output
            String mockResponse = '{"generations":[{"text":"```json { \\"message\\": \\"Corrected text\\" } ```"}]}';

            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testSendRequest() {

        // Set mock response
        Test.setMock(HttpCalloutMock.class, new EinsteinLLMMock());

        Test.startTest();

        String inputText = 'this is bad grammar';
        String apiName = 'Test_Field__c';

        String result = DHSGrammarCheckController.sendRequest(inputText, apiName);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');

        // Validate JSON structure
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(parsed.containsKey('message'), 'Response should contain message key');
    }

    @isTest
    static void testProcessSingle_NullResponse() {

        // No mock set → should hit exception or return null safely
        Test.startTest();

        String result;
        try {
            result = DHSGrammarCheckController.sendRequest('test', 'Field__c');
        } catch (Exception e) {
            result = null;
        }

        Test.stopTest();

        System.assertNotEquals(null, result, 'The controller returns a safe fallback response');
        System.assert(result.contains('Grammar check is unavailable'), 'Assertion failed in DHSGrammarCheckControllerTest at source line 59');
    }
}