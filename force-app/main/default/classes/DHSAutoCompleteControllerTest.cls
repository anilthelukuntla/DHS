@IsTest
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

        System.assertNotEquals(null, result, 'Expected the asserted condition to hold');
        System.assert(result.contains(String.valueOf(currentUser.Id)), 'Expected assertion condition to hold');
    }
}