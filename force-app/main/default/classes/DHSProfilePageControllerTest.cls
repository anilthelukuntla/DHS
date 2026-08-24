@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSProfilePageControllerTest {
    @IsTest
    static void loadsCurrentUsersProfile() {
        Test.setCurrentPage(Page.DHSProfilePage);
        ApexPages.currentPage().getParameters().put('id', UserInfo.getUserId());

        DHSProfilePageController controller = new DHSProfilePageController();
        controller.userRecord.Out_of_office__c = 'Vacation';
        controller.updatefieldfisibility();
        PageReference result = controller.updateuserrecordaction();

        System.assertEquals(null, result, 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.showFields, 'Expected the asserted condition to hold');
        System.assertEquals(UserInfo.getUserId(), controller.userRecord.Id, 'Expected the asserted condition to hold');
    }
}
