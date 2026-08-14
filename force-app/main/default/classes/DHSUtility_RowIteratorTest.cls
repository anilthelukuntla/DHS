@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ForLoopsMustUseBraces')
@IsTest private class DHSUtility_RowIteratorTest {
 @IsTest static void iteratesRows(){DHSUtility_RowIterator it=new DHSUtility_RowIterator('one\ntwo','\n');List<String> rows=new List<String>();for(String row:it)rows.add(row);System.assertEquals(new List<String>{'one','two'},rows,'Iterator should return both rows in order.');}
}