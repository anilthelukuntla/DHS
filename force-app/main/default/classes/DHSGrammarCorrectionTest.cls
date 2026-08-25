@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest private class DHSGrammarCorrectionTest {
 @IsTest static void correctsGrammar(){System.assertEquals('',DHSGrammarCorrection.correctGrammar(null,null), 'Expected the asserted condition to hold');System.assertEquals('Text',DHSGrammarCorrection.correctGrammar('Text','Field__c'), 'Expected the asserted condition to hold');}
}