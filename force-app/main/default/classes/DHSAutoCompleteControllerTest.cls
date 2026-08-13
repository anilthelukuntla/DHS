@IsTest
/** Exercises the existing DHSAutoCompleteController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSAutoCompleteControllerTest {
    @IsTest
    static void returnsMatchingUserAsJson() {
        User currentUser = [
            SELECT Id, FirstName
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        Test.setCurrentPage(Page.DHSAutoCompleteJSON);
        ApexPages.currentPage().getParameters().put('q', currentUser.FirstName);
        ApexPages.currentPage().getParameters().put('obj', 'User');
        ApexPages.currentPage().getParameters().put('label', 'FirstName');
        ApexPages.currentPage().getParameters().put('detail', 'Email,LastName');
        ApexPages.currentPage().getParameters().put('value', 'Id');

        String result = new DHSAutoCompleteController().getJSON();

        System.assertNotEquals(null, result, 'Assertion failed in DHSAutoCompleteControllerTest at source line 21');
        System.assert(result.contains(String.valueOf(currentUser.Id)), 'Assertion failed in DHSAutoCompleteControllerTest at source line 22');

        ApexPages.currentPage().getParameters().put('obj', 'NotAnObject');
        System.assertEquals('[]', new DHSAutoCompleteController().getJSON(), 'Assertion failed in DHSAutoCompleteControllerTest at source line 25');
    }
}