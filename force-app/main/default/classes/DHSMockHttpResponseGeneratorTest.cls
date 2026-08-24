@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
@IsTest private class DHSMockHttpResponseGeneratorTest {
 @IsTest static void returnsResponse(){HttpResponse r=new DHSMockHttpResponseGenerator('{"ok":true}').respond(new HttpRequest());System.assertEquals(200,r.getStatusCode());System.assertEquals('{"ok":true}',r.getBody());}
}
