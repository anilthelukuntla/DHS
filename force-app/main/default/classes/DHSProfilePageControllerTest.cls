@IsTest
/** Exercises the existing DHSProfilePageController behavior. */
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

        System.assertEquals(null, result, 'Assertion failed in DHSProfilePageControllerTest at source line 15');
        System.assertEquals(true, controller.showFields, 'Assertion failed in DHSProfilePageControllerTest at source line 16');
        System.assertEquals(UserInfo.getUserId(), controller.userRecord.Id, 'Assertion failed in DHSProfilePageControllerTest at source line 17');
    }
}