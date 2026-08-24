@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest private class DHSGrammarCorrectionTest {
 @IsTest static void correctsGrammar(){System.assertEquals('',DHSGrammarCorrection.correctGrammar(null,null));System.assertEquals('Text',DHSGrammarCorrection.correctGrammar('Text','Field__c'));}
}
