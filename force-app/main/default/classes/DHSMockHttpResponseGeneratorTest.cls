@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest private class DHSMockHttpResponseGeneratorTest {
 @IsTest static void returnsResponse(){HttpResponse r=new DHSMockHttpResponseGenerator('{"ok":true}').respond(new HttpRequest());System.assertEquals(200,r.getStatusCode(), 'Expected the asserted condition to hold');System.assertEquals('{"ok":true}',r.getBody(), 'Expected the asserted condition to hold');}
}
