@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest private class DHSCustomDataTableHandlerTest {
 @IsTest static void buildsAndEditsRows(){insert new Contact(LastName='Coverage');DHSCustomDataTableHandler h=new DHSCustomDataTableHandler();System.assert(!h.rows.isEmpty());String id=String.valueOf(h.rows[0].get('id'));DHSCustomDataTableHandler.editField(id);System.assert(DHSCustomDataTableHandler.originalRows.containsKey('worked'));}
}
