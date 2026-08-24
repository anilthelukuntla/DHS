@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSProfilePageControllerTest {
    @IsTest
    static void loadsCurrentUsersProfile() {
        Test.setCurrentPage(Page.DHSProfilePage);
        ApexPages.currentPage().getParameters().put('id', UserInfo.getUserId());

        DHSProfilePageController controller = new DHSProfilePageController();
        controller.userRecord.Out_of_office__c = 'Vacation';
        controller.updatefieldfisibility();
        PageReference result = controller.updateuserrecordaction();

        System.assertEquals(null, result);
        System.assertEquals(true, controller.showFields);
        System.assertEquals(UserInfo.getUserId(), controller.userRecord.Id);
    }
}
