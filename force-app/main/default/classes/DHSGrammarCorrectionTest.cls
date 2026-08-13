@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest private class DHSGrammarCorrectionTest {
 @IsTest static void correctsGrammar(){System.assertEquals('',DHSGrammarCorrection.correctGrammar(null,null), 'Assertion failed in DHSGrammarCorrectionTest at source line 3');System.assertEquals('Text',DHSGrammarCorrection.correctGrammar('Text','Field__c'), 'Assertion failed in DHSGrammarCorrectionTest at source line 3');}
}