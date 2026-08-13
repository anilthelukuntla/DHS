@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DHSMockHttpResponseGeneratorTest {
    @IsTest
    static void returnsDhsResponse() {
        HttpResponse response = new DHSMockHttpResponseGenerator(
            '{"ok":true}'
        ).respond(new HttpRequest());
        System.assertEquals(200, response.getStatusCode(), 'Assertion failed in DHSMockHttpResponseGeneratorTest at source line 9');
        System.assertEquals('{"ok":true}', response.getBody(), 'Assertion failed in DHSMockHttpResponseGeneratorTest at source line 10');
        System.assertEquals(
            'application/json',
            response.getHeader('Content-Type')
        , 'Assertion failed in DHSMockHttpResponseGeneratorTest at source line 11');
    }

    @IsTest
    static void returnsPpfResponse() {
        HttpResponse response = new MockHttpResponseGenerator(
            '{"ok":true}'
        ).respond(new HttpRequest());
        System.assertEquals(200, response.getStatusCode(), 'Assertion failed in DHSMockHttpResponseGeneratorTest at source line 22');
        System.assertEquals('{"ok":true}', response.getBody(), 'Assertion failed in DHSMockHttpResponseGeneratorTest at source line 23');
        System.assertEquals(
            'application/json',
            response.getHeader('Content-Type')
        , 'Assertion failed in DHSMockHttpResponseGeneratorTest at source line 24');
    }
}